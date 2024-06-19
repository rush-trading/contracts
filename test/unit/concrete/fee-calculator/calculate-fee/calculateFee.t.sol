// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";

import { FeeCalculator_Unit_Shared_Test } from "test/unit/shared/FeeCalculator.t.sol";

contract CalculateFee_Unit_Concrete_Test is FeeCalculator_Unit_Shared_Test {
    function setUp() public virtual override {
        FeeCalculator_Unit_Shared_Test.setUp();
    }

    function test_GivenUtilizationIsGreaterThanOptimalUtilization() external view {
        // TODO: use Defaults utility to get the default values
        uint256 duration = 31_536_000; // 1 year
        uint256 newLiquidity = 50_000e18; // 50K tokens
        uint256 outstandingLiquidity = 900_000e18; // 900K tokens
        uint256 totalLiquidity = 1_000_000e18; // 1M tokens

        uint256 utilizationRatio = (ud(outstandingLiquidity + newLiquidity) / ud(totalLiquidity)).intoUint256();
        assertGt(utilizationRatio, defaults.OPTIMAL_UTILIZATION_RATIO(), "utilizationRatio");

        (uint256 actualTotalFee, uint256 actualReserveFee) = feeCalculator.calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        // TODO: replace with scripts to calculate the expected values
        uint256 expectedTotalFee = 83_312_499_995_352_000_000_000;
        uint256 expectedReserveFee = 8_331_249_999_535_200_000_000;
        assertEq(actualTotalFee, expectedTotalFee);
        assertEq(actualReserveFee, expectedReserveFee);
    }

    function test_GivenUtilizationIsLessThanOrEqOptimalUtilization() external view {
        uint256 duration = 31_536_000; // 1 year
        uint256 newLiquidity = 5000e18; // 5K tokens
        uint256 outstandingLiquidity = 85_000e18; // 85K tokens
        uint256 totalLiquidity = 1_000_000e18; // 1M tokens

        uint256 utilizationRatio = (ud(outstandingLiquidity + newLiquidity) / ud(totalLiquidity)).intoUint256();
        assertLt(utilizationRatio, defaults.OPTIMAL_UTILIZATION_RATIO(), "utilizationRatio");

        (uint256 actualTotalFee, uint256 actualReserveFee) = feeCalculator.calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        // TODO: replace with scripts to calculate the expected values
        uint256 expectedTotalFee = 5_007_499_999_725_600_000_000;
        uint256 expectedReserveFee = 500_749_999_972_560_000_000;
        assertEq(actualTotalFee, expectedTotalFee);
        assertEq(actualReserveFee, expectedReserveFee);
    }
}
