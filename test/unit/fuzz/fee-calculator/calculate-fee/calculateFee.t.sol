// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { FC } from "src/types/DataTypes.sol";
import { FeeCalculator_Unit_Shared_Test } from "test/unit/shared/FeeCalculator.t.sol";

contract CalculateFee_Unit_Fuzz_Test is FeeCalculator_Unit_Shared_Test {
    function setUp() public virtual override {
        FeeCalculator_Unit_Shared_Test.setUp();
    }

    function test_GivenUtilizationIsGreaterThanOptimalUtilization(
        uint256 duration,
        uint256 utilizationRatio,
        uint256 outstandingLiquidity,
        uint256 reserveFactor,
        uint256 totalLiquidity
    )
        external
        view
    {
        duration = bound(duration, defaults.MIN_LIQUIDITY_DURATION(), defaults.MAX_LIQUIDITY_DURATION());
        utilizationRatio = bound(utilizationRatio, feeCalculator.OPTIMAL_UTILIZATION_RATIO() + 1, 1e18);
        totalLiquidity = bound(totalLiquidity, defaults.MIN_TOTAL_LIQUIDITY(), defaults.MAX_TOTAL_LIQUIDITY());

        // Calculate new outstanding liquidity (after adding new liquidity).
        uint256 outstandingPlusNewLiquidity = Math.mulDiv(utilizationRatio, totalLiquidity, 1e18);

        // Bound the current outstanding liquidity.
        outstandingLiquidity = bound(outstandingLiquidity, 0, outstandingPlusNewLiquidity);
        reserveFactor = bound(reserveFactor, 0, 1e18);
        // Calculate the new liquidity to be added.
        uint256 newLiquidity = outstandingPlusNewLiquidity - outstandingLiquidity;

        // Fetch the fees from the FeeCalculator.
        (uint256 totalFee, uint256 reserveFee) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: reserveFactor,
                totalLiquidity: totalLiquidity
            })
        );

        // Assert that the fees are within the expected range.
        uint256 minFeeRate = defaults.FEE_RATE_U_OPT();
        (uint256 minTotalFee, uint256 minReserveFee) = calculateFee({
            duration: duration,
            feeRate: minFeeRate,
            newLiquidity: newLiquidity,
            reserveFactor: reserveFactor
        });
        assertGe(totalFee, minTotalFee, "minTotalFee");
        assertGe(reserveFee, minReserveFee, "minReserveFee");

        uint256 maxFeeRate = defaults.FEE_RATE_U_100();
        (uint256 maxTotalFee, uint256 maxReserveFee) = calculateFee({
            duration: duration,
            feeRate: maxFeeRate,
            newLiquidity: newLiquidity,
            reserveFactor: reserveFactor
        });
        assertLe(totalFee, maxTotalFee, "maxTotalFee");
        assertLe(reserveFee, maxReserveFee, "maxReserveFee");
    }

    function test_GivenUtilizationIsLessThanOrEqOptimalUtilization(
        uint256 duration,
        uint256 utilizationRatio,
        uint256 outstandingLiquidity,
        uint256 reserveFactor,
        uint256 totalLiquidity
    )
        external
        view
    {
        duration = bound(duration, defaults.MIN_LIQUIDITY_DURATION(), defaults.MAX_LIQUIDITY_DURATION());
        utilizationRatio = bound(utilizationRatio, 0, feeCalculator.OPTIMAL_UTILIZATION_RATIO());
        totalLiquidity = bound(totalLiquidity, defaults.MIN_TOTAL_LIQUIDITY(), defaults.MAX_TOTAL_LIQUIDITY());

        // Calculate new outstanding liquidity (after adding new liquidity).
        uint256 outstandingPlusNewLiquidity = Math.mulDiv(utilizationRatio, totalLiquidity, 1e18);

        // Bound the current outstanding liquidity.
        outstandingLiquidity = bound(outstandingLiquidity, 0, outstandingPlusNewLiquidity);
        reserveFactor = bound(reserveFactor, 0, 1e18);
        // Calculate the new liquidity to be added.
        uint256 newLiquidity = outstandingPlusNewLiquidity - outstandingLiquidity;

        // Fetch the fees from the FeeCalculator.
        (uint256 totalFee, uint256 reserveFee) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: newLiquidity,
                outstandingLiquidity: outstandingLiquidity,
                reserveFactor: reserveFactor,
                totalLiquidity: totalLiquidity
            })
        );

        // Assert that the fees are within the expected range.
        uint256 minFeeRate = defaults.FEE_RATE_U_000();
        (uint256 minTotalFee, uint256 minReserveFee) = calculateFee({
            duration: duration,
            feeRate: minFeeRate,
            newLiquidity: newLiquidity,
            reserveFactor: reserveFactor
        });
        assertGe(totalFee, minTotalFee, "minTotalFee");
        assertGe(reserveFee, minReserveFee, "minReserveFee");

        uint256 maxFeeRate = defaults.FEE_RATE_U_OPT();
        (uint256 maxTotalFee, uint256 maxReserveFee) = calculateFee({
            duration: duration,
            feeRate: maxFeeRate,
            newLiquidity: newLiquidity,
            reserveFactor: reserveFactor
        });
        assertLe(totalFee, maxTotalFee, "maxTotalFee");
        assertLe(reserveFee, maxReserveFee, "maxReserveFee");
    }
}
