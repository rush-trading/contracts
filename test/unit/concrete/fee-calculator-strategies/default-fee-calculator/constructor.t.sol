// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { DefaultFeeCalculator } from "src/fee-calculator/strategies/DefaultFeeCalculator.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_DefaultFeeCalculator_Unit_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Construct the contract.
        DefaultFeeCalculator constructedFeeCalculator = new DefaultFeeCalculator({
            baseFeeRate: defaults.BASE_FEE_RATE(),
            optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO(),
            rateSlope1: defaults.RATE_SLOPE1(),
            rateSlope2: defaults.RATE_SLOPE2()
        });

        // Assert that the values were set correctly.
        uint256 actualBaseFeeRate = constructedFeeCalculator.BASE_FEE_RATE();
        uint256 expectedBaseFeeRate = defaults.BASE_FEE_RATE();
        assertEq(actualBaseFeeRate, expectedBaseFeeRate, "BASE_FEE_RATE");

        uint256 actualOptimalUtilizationRatio = constructedFeeCalculator.OPTIMAL_UTILIZATION_RATIO();
        uint256 expectedOptimalUtilizationRatio = defaults.OPTIMAL_UTILIZATION_RATIO();
        assertEq(actualOptimalUtilizationRatio, expectedOptimalUtilizationRatio, "OPTIMAL_UTILIZATION_RATIO");

        uint256 actualMaxExcessUtilizationRatio = constructedFeeCalculator.MAX_EXCESS_UTILIZATION_RATIO();
        uint256 expectedMaxExcessUtilizationRatio = 1e18 - defaults.OPTIMAL_UTILIZATION_RATIO();
        assertEq(actualMaxExcessUtilizationRatio, expectedMaxExcessUtilizationRatio, "MAX_EXCESS_UTILIZATION_RATIO");

        uint256 actualRateSlope1 = constructedFeeCalculator.RATE_SLOPE1();
        uint256 expectedRateSlope1 = defaults.RATE_SLOPE1();
        assertEq(actualRateSlope1, expectedRateSlope1, "RATE_SLOPE1");

        uint256 actualRateSlope2 = constructedFeeCalculator.RATE_SLOPE2();
        uint256 expectedRateSlope2 = defaults.RATE_SLOPE2();
        assertEq(actualRateSlope2, expectedRateSlope2, "RATE_SLOPE2");
    }
}
