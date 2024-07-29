// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { FC } from "src/types/DataTypes.sol";

import { FeeCalculator_Unit_Shared_Test } from "test/unit/shared/FeeCalculator.t.sol";

contract CalculateFee_Unit_Concrete_Test is FeeCalculator_Unit_Shared_Test {
    function setUp() public virtual override {
        FeeCalculator_Unit_Shared_Test.setUp();
    }

    function test_GivenUtilizationIsGreaterThanOptimalUtilization() external view {
        uint256 duration = 1 hours; // 1 hour
        uint256 newLiquidity = 0.1 ether; // 0.1 WETH
        uint256 outstandingLiquidity = 98.9 ether; // 98.9 WETH
        uint256 totalLiquidity = 100 ether; // 100 WETH

        uint256 utilizationRatio = (ud(outstandingLiquidity + newLiquidity) / ud(totalLiquidity)).intoUint256();
        assertGt(utilizationRatio, defaults.OPTIMAL_UTILIZATION_RATIO(), "utilizationRatio");

        (uint256 actualTotalFee, uint256 actualReserveFee) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        (uint256 expectedTotalFee, uint256 expectedReserveFee) = calculateFee({
            duration: duration,
            feeRate: calculateFeeRate({
                baseFeeRate: defaults.BASE_FEE_RATE(),
                rateSlope1: defaults.RATE_SLOPE_1(),
                rateSlope2: defaults.RATE_SLOPE_2(),
                utilizationRatio: utilizationRatio,
                optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO()
            }),
            newLiquidity: newLiquidity,
            reserveFactor: defaults.RESERVE_FACTOR()
        });
        assertEq(actualTotalFee, expectedTotalFee);
        assertEq(actualReserveFee, expectedReserveFee);
    }

    function test_GivenUtilizationIsLessThanOrEqOptimalUtilization() external view {
        uint256 duration = 1 hours; // 1 hour
        uint256 newLiquidity = 0.1 ether; // 0.1 WETH
        uint256 outstandingLiquidity = 4.9 ether; // 4.9 WETH
        uint256 totalLiquidity = 100 ether; // 100 WETH

        uint256 utilizationRatio = (ud(outstandingLiquidity + newLiquidity) / ud(totalLiquidity)).intoUint256();
        assertLt(utilizationRatio, defaults.OPTIMAL_UTILIZATION_RATIO(), "utilizationRatio");

        (uint256 actualTotalFee, uint256 actualReserveFee) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        (uint256 expectedTotalFee, uint256 expectedReserveFee) = calculateFee({
            duration: duration,
            feeRate: calculateFeeRate({
                baseFeeRate: defaults.BASE_FEE_RATE(),
                rateSlope1: defaults.RATE_SLOPE_1(),
                rateSlope2: defaults.RATE_SLOPE_2(),
                utilizationRatio: utilizationRatio,
                optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO()
            }),
            newLiquidity: newLiquidity,
            reserveFactor: defaults.RESERVE_FACTOR()
        });
        assertEq(actualTotalFee, expectedTotalFee);
        assertEq(actualReserveFee, expectedReserveFee);
    }
}
