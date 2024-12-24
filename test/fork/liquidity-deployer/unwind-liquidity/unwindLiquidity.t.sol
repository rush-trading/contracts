// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LD } from "src/types/DataTypes.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract UnwindLiquidity_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_ContractIsPaused() external {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });

        // Pause the contract.
        liquidityDeployer.pause();

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.EnforcedPause.selector));
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    modifier whenContractIsNotPaused() {
        _;
    }

    function test_RevertGiven_PairHasNotReceivedLiquidity() external whenContractIsNotPaused {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairNotReceivedLiquidity.selector, uniV2Pair));
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    modifier givenPairHasReceivedLiquidity() {
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 feeAmount = getDeployLiquidityFee({ amount: amount, duration: duration });

        // Deploy the liquidity.
        deployLiquidity({
            originator_: users.sender,
            uniV2Pair_: uniV2Pair,
            rushERC20_: rushERC20Mock,
            rushERC20Amount_: defaults.RUSH_ERC20_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });
        _;
    }

    function test_RevertGiven_PairHasAlreadyBeenUnwound()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
    {
        // Simulate the passage of time.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Unwind the liquidity.
        unwindLiquidity({ uniV2Pair_: uniV2Pair });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairAlreadyUnwound.selector, uniV2Pair));
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    modifier givenPairHasNotBeenUnwound() {
        _;
    }

    function test_RevertGiven_DeadlineHasNotPassedAndEarlyUnwindThresholdIsNotReached()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_UnwindNotReady.selector, uniV2Pair, liquidityDeployment.deadline, false
            )
        );
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    function test_GivenDeadlineHasNotPassedButEarlyUnwindThresholdIsReached()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Set WETH reserve to be at the early unwind threshold.
        deal({
            token: address(weth),
            to: uniV2Pair,
            give: defaults.LIQUIDITY_AMOUNT() + liquidityDeployer.EARLY_UNWIND_THRESHOLD()
        });
        IUniswapV2Pair(uniV2Pair).sync();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceBefore = weth.balanceOf(users.reserve);
        bool isUnwindThresholdMetBefore = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        uint256 reserveWETHBalanceAfter = weth.balanceOf(users.reserve);
        bool isUnwindThresholdMetAfter = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that the reserve received some WETH (fees).
        vm.assertGt(reserveWETHBalanceAfter, reserveWETHBalanceBefore, "balanceOf");
        // Assert that the unwind threshold was met.
        vm.assertEq(isUnwindThresholdMetBefore, false, "isUnwindThresholdMetBefore");
        vm.assertEq(isUnwindThresholdMetAfter, true, "isUnwindThresholdMetAfter");
    }

    modifier givenDeadlineHasPassedButEarlyUnwindThresholdIsNotReached() {
        _;
    }

    function test_WhenAssetBalanceOfPairIsStillSameAsInitialBalance()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
        givenDeadlineHasPassedButEarlyUnwindThresholdIsNotReached
    {
        // Set time to be at the deadline.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetBefore = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetAfter = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that the unwind threshold wasn't met.
        vm.assertEq(isUnwindThresholdMetBefore, false, "isUnwindThresholdMetBefore");
        vm.assertEq(isUnwindThresholdMetAfter, false, "isUnwindThresholdMetAfter");
    }

    function test_WhenAssetBalanceOfPairIsAboveInitialBalance()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
        givenDeadlineHasPassedButEarlyUnwindThresholdIsNotReached
    {
        // Set time to be at the deadline.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Send WETH amount to the pair to trigger the surplus condition.
        uint256 wethAmount = 10_000;
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.sender });
        deal({ token: address(weth), to: users.sender, give: wethAmount });
        weth.transfer(uniV2Pair, wethAmount);
        resetPrank({ msgSender: caller });

        // Calculate the amounts of WETH and RUSH ERC20 to be resupplied to the pair.
        uint256 wethAmountToResupply = wethAmount - 2;
        (uint256 wethReserve, uint256 rushERC20Reserve,) = IUniswapV2Pair(uniV2Pair).getReserves();
        uint256 rushERC20ToResupply = Math.mulDiv(rushERC20Reserve, wethAmountToResupply, wethReserve * 4);

        // Expect the relevant event to be emitted on the pair.
        vm.expectEmit({
            emitter: address(uniV2Pair),
            checkTopic1: true,
            checkTopic2: true,
            checkTopic3: true,
            checkData: true
        });
        emit Mint({ sender: address(liquidityDeployer), amount0: wethAmountToResupply, amount1: rushERC20ToResupply });

        // Expect the relevant event to be emitted on LiquidityDeployer.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity and gracefully handle `IUniswapV2Pair.mint` revert with `IUniswapV2Pair.sync`.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetBefore = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetAfter = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that the unwind threshold wasn't met.
        vm.assertEq(isUnwindThresholdMetBefore, false, "isUnwindThresholdMetBefore");
        vm.assertEq(isUnwindThresholdMetAfter, false, "isUnwindThresholdMetAfter");
    }

    function test_GivenDeadlineHasPassedAndEarlyUnwindThresholdIsReached()
        external
        whenContractIsNotPaused
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Set time to be at the deadline.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Set WETH reserve to be at the early unwind threshold.
        deal({
            token: address(weth),
            to: uniV2Pair,
            give: defaults.LIQUIDITY_AMOUNT() + liquidityDeployer.EARLY_UNWIND_THRESHOLD()
        });
        IUniswapV2Pair(uniV2Pair).sync();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        uint256 lpBalanceBefore = IERC20(uniV2Pair).balanceOf(address(rushERC20Mock));
        uint256 tokenBalanceBefore = IERC20(rushERC20Mock).balanceOf(users.burn);
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetBefore = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 lpBalanceAfter = IERC20(uniV2Pair).balanceOf(address(rushERC20Mock));
        uint256 tokenBalanceAfter = IERC20(rushERC20Mock).balanceOf(users.burn);
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));
        bool isUnwindThresholdMetAfter = liquidityDeployer.getLiquidityDeployment(uniV2Pair).isUnwindThresholdMet;

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "liquidtyPoolWETHBalanceDiff"
        );
        // Assert that the unwind threshold wasn't met.
        vm.assertEq(isUnwindThresholdMetBefore, false, "isUnwindThresholdMetBefore");
        vm.assertEq(isUnwindThresholdMetAfter, true, "isUnwindThresholdMetAfter");
        // Assert that excess liquidity was re-added to the pair and tokens locked in token contract itself.
        vm.assertEq(lpBalanceBefore, 0, "lpBalanceBefore");
        vm.assertGt(lpBalanceAfter, 0, "lpBalanceAfter");
        // Assert that tokens were burned by sending them to the token contract itself.
        vm.assertEq(tokenBalanceBefore, 0, "tokenBalanceBefore");
        vm.assertGt(tokenBalanceAfter, 0, "tokenBalanceAfter");
    }
}
