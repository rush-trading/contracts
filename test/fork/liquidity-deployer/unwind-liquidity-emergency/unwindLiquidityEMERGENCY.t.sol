// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

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
            rushERC20Amount_: defaults.MAX_RUSH_ERC20_SUPPLY(),
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

    function test_GivenPairHasNotBeenUnwound()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
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
}
