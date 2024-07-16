// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LD } from "src/types/DataTypes.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract UnwindLiquidity_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertGiven_PairHasNotReceivedLiquidity() external {
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
            rushERC20Amount_: defaults.RUSH_ERC20_MAX_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });
        _;
    }

    function test_RevertGiven_PairHasAlreadyBeenUnwound() external givenPairHasReceivedLiquidity {
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
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        uint256 currentReserve = IERC20(weth).balanceOf(uniV2Pair);
        uint256 targetReserve = defaults.LIQUIDITY_AMOUNT() + liquidityDeployer.EARLY_UNWIND_THRESHOLD();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_UnwindNotReady.selector,
                uniV2Pair,
                liquidityDeployment.deadline,
                currentReserve,
                targetReserve
            )
        );
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    function test_GivenDeadlineHasNotPassedButEarlyUnwindThresholdIsReached()
        external
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
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
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

    function test_GivenDeadlineHasPassedButEarlyUnwindThresholdIsNotReached()
        external
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Set time to be at the deadline.
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        vm.warp(liquidityDeployment.deadline);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: users.sender, amount: defaults.LIQUIDITY_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
    }

    function test_GivenDeadlineHasPassedAndEarlyUnwindThresholdIsReached()
        external
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
        uint256 address1LPBalanceBefore = IERC20(uniV2Pair).balanceOf(address(1));
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        uint256 address1LPBalanceAfter = IERC20(uniV2Pair).balanceOf(address(1));
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.LIQUIDITY_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
        // Assert that excess liquidity was re-added to the pair.
        vm.assertEq(address1LPBalanceBefore, 0, "balanceOf");
        vm.assertGt(address1LPBalanceAfter, 0, "balanceOf");
    }
}
