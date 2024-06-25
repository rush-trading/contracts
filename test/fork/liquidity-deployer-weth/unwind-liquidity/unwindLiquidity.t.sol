// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { LiquidityDeployerWETH_Fork_Test } from "../LiquidityDeployerWETH.t.sol";

contract UnwindLiquidity_Fork_Test is LiquidityDeployerWETH_Fork_Test {
    function test_RevertGiven_PairHasNotReceivedLiquidity() external {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairNotReceivedLiquidity.selector, pair));
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
    }

    modifier givenPairHasReceivedLiquidity() {
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 feeAmount = defaults.FEE_AMOUNT();

        // Deploy the liquidity.
        deployLiquidity({
            originator_: users.sender,
            pair_: pair,
            token_: token,
            tokenAmount_: defaults.TOKEN_MAX_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });
        _;
    }

    function test_RevertGiven_PairHasAlreadyBeenUnwound() external givenPairHasReceivedLiquidity {
        // Simulate the passage of time.
        (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
        vm.warp(deadline);

        // Unwind the liquidity.
        unwindLiquidity({ pair_: pair });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairAlreadyUnwound.selector, pair));
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
    }

    modifier givenPairHasNotBeenUnwound() {
        _;
    }

    function test_RevertGiven_DeadlineHasNotPassedAndEarlyUnwindThresholdIsNotReached()
        external
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
        uint256 currentReserve = IERC20(weth).balanceOf(pair);
        uint256 targetReserve = defaults.DISPATCH_AMOUNT() + liquidityDeployerWETH.EARLY_UNWIND_THRESHOLD();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_UnwindNotReady.selector, pair, deadline, currentReserve, targetReserve
            )
        );
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
    }

    function test_GivenDeadlineHasNotPassedButEarlyUnwindThresholdIsReached()
        external
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Set WETH reserve to be at the early unwind threshold.
        deal({
            token: address(weth),
            to: pair,
            give: defaults.DISPATCH_AMOUNT() + liquidityDeployerWETH.EARLY_UNWIND_THRESHOLD()
        });
        IUniswapV2Pair(pair).sync();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit UnwindLiquidity({ pair: pair, originator: users.sender, amount: defaults.DISPATCH_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.DISPATCH_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );

        // TODO: assert that the reserve fee was paid in all successful tests.
        // TODO: assert that excess liquidity was re-added to the pair in relevant successful tests.
    }

    function test_GivenDeadlineHasPassedButEarlyUnwindThresholdIsNotReached()
        external
        givenPairHasReceivedLiquidity
        givenPairHasNotBeenUnwound
    {
        // Set time to be at the deadline.
        (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
        vm.warp(deadline);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit UnwindLiquidity({ pair: pair, originator: users.sender, amount: defaults.DISPATCH_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.DISPATCH_AMOUNT();
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
        (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
        vm.warp(deadline);

        // Set WETH reserve to be at the early unwind threshold.
        deal({
            token: address(weth),
            to: pair,
            give: defaults.DISPATCH_AMOUNT() + liquidityDeployerWETH.EARLY_UNWIND_THRESHOLD()
        });
        IUniswapV2Pair(pair).sync();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit UnwindLiquidity({ pair: pair, originator: users.sender, amount: defaults.DISPATCH_AMOUNT() });

        // Unwind the liquidity.
        uint256 liquidityPoolWETHBalanceBefore = weth.balanceOf(address(liquidityPool));
        liquidityDeployerWETH.unwindLiquidity({ pair: pair });
        uint256 liquidityPoolWETHBalanceAfter = weth.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.DISPATCH_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );
    }
}
