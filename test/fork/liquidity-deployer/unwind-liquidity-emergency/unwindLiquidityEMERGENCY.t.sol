// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LD } from "src/types/DataTypes.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract UnwindLiquidityEMERGENCY__Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
    }

    modifier whenCallerHasAdminRole() {
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ContractIsNotPaused() external whenCallerHasAdminRole {
        // Run the test.
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        vm.expectRevert(abi.encodeWithSelector(Errors.ExpectedPause.selector));
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
    }

    modifier whenContractIsPaused() {
        // Pause the contract.
        liquidityDeployer.pause();
        _;
    }

    function test_RevertGiven_PairHasNotReceivedLiquidity() external whenCallerHasAdminRole whenContractIsPaused {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairNotReceivedLiquidity.selector, uniV2Pair));
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
    }

    modifier givenPairHasReceivedLiquidity() {
        (, address caller,) = vm.readCallers();
        // Momentarily unpause the contract to deploy the liquidity.
        resetPrank({ msgSender: users.admin });
        liquidityDeployer.unpause();
        // Deploy the liquidity.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 feeAmount = getDeployLiquidityFee({ amount: amount, duration: duration });
        deployLiquidity({
            originator_: users.sender,
            uniV2Pair_: uniV2Pair,
            rushERC20_: rushERC20Mock,
            rushERC20Amount_: defaults.RUSH_ERC20_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });
        // Pause the contract again.
        resetPrank({ msgSender: users.admin });
        liquidityDeployer.pause();
        resetPrank({ msgSender: caller });
        _;
    }

    function test_RevertGiven_PairHasAlreadyBeenUnwound()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
    {
        // Simulate the passage of time.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Unwind the liquidity.
        unwindLiquidity({ uniV2Pair_: uniV2Pair });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairAlreadyUnwound.selector, uniV2Pair));
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
    }

    modifier givenPairHasNotBeenUnwound() {
        _;
    }

    function test_WhenAssetBalanceOfPairIsStillSameAsInitialBalance()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceBefore = weth.balanceOf(users.reserve);
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceAfter = weth.balanceOf(users.reserve);

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that the reserve received some WETH (fees).
        vm.assertGt(reserveWETHBalanceAfter, reserveWETHBalanceBefore, "balanceOf");
    }

    function test_WhenAssetBalanceOfPairIsAboveInitialBalance()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Send WETH amount to the pair to trigger the surplus condition.
        uint256 wethAmount = 10_000;
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.sender });
        deal({ token: address(weth), to: users.sender, give: wethAmount });
        weth.transfer(uniV2Pair, wethAmount);
        resetPrank({ msgSender: caller });

        // Calculate the amounts of WETH and RUSH ERC20 to be resupplied to the pair.
        uint256 wethAmountToResupply = Math.mulDiv(wethAmount, 1e18 - defaults.RESERVE_FACTOR(), 1e18) - 1;
        (uint256 wethReserve, uint256 rushERC20Reserve,) = IUniswapV2Pair(uniV2Pair).getReserves();
        uint256 rushERC20ToResupply = Math.mulDiv(wethAmountToResupply, rushERC20Reserve, wethReserve);

        // Expect the relevant event to be emitted on the pair.
        vm.expectEmit({
            emitter: address(uniV2Pair),
            checkTopic1: true,
            checkTopic2: true,
            checkTopic3: true,
            checkData: true
        });
        emit Mint({ sender: address(liquidityDeployer), amount0: wethAmountToResupply, amount1: rushERC20ToResupply });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        address[] memory uniV2Pairs = new address[](1);
        uniV2Pairs[0] = uniV2Pair;
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceBefore = weth.balanceOf(users.reserve);
        liquidityDeployer.unwindLiquidityEMERGENCY({ uniV2Pairs: uniV2Pairs });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceAfter = weth.balanceOf(users.reserve);

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that the reserve received some WETH (fees).
        vm.assertGt(reserveWETHBalanceAfter, reserveWETHBalanceBefore, "balanceOf");
    }
}
