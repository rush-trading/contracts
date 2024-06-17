// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { DefaultFeeCalculator } from "src/fee-calculator/strategies/DefaultFeeCalculator.sol";

import { DefaultFeeCalculator_Unit_Shared_Test } from "test/unit/shared/DefaultFeeCalculator.t.sol";

contract CalculateFee_Unit_Concrete_Test is DefaultFeeCalculator_Unit_Shared_Test {
    function setUp() public virtual override {
        DefaultFeeCalculator_Unit_Shared_Test.setUp();
    }

    function test_GivenUtilizationIsGreaterThanOptimalUtilization() external view {
        uint256 duration = 31_536_000; // 1 year
        uint256 newLiquidity = 50_000e18; // 50K tokens
        uint256 outstandingLiquidity = 900_000e18; // 900K tokens
        uint256 totalLiquidity = 1_000_000e18; // 1M tokens

        uint256 utilizationRatio = (ud(outstandingLiquidity + newLiquidity) / ud(totalLiquidity)).intoUint256();
        assertGt(utilizationRatio, defaults.OPTIMAL_UTILIZATION_RATIO(), "utilizationRatio");

        (uint256 actualTotalFee, uint256 actualReserveFee) = feeCalculator.calculateFee(
            DefaultFeeCalculator.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        // TODO: replace with scripts to calculate the expected values
        uint256 expectedTotalFee = 2_627_343_000_000e18;
        uint256 expectedReserveFee = 262_734_300_000e18;
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
            DefaultFeeCalculator.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: totalLiquidity
            })
        );

        // TODO: replace with scripts to calculate the expected values
        uint256 expectedTotalFee = 157_916_520_000e18;
        uint256 expectedReserveFee = 15_791_652_000e18;
        assertEq(actualTotalFee, expectedTotalFee);
        assertEq(actualReserveFee, expectedReserveFee);
    }
}
