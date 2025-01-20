// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { FC } from "src/types/DataTypes.sol";

/**
 * @title FeeCalculator
 * @notice See the documentation in {IFeeCalculator}.
 */
contract FeeCalculator is IFeeCalculator {
    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override BASE_FEE_RATE;

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override MAX_EXCESS_UTILIZATION_RATIO;

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override OPTIMAL_UTILIZATION_RATIO;

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override RATE_SLOPE_1;

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override RATE_SLOPE_2;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param baseFeeRate The base fee rate when U (the utilization ratio) is 0.
     * @param optimalUtilizationRatio The utilization ratio at which LiquidityPool aims to obtain most competitive fee
     * rates.
     * @param rateSlope1 The slope of the interest rate curve when U is >= 0% and <= U_optimal.
     * @param rateSlope2 The slope of the interest rate curve when U is > U_optimal.
     */
    constructor(uint256 baseFeeRate, uint256 optimalUtilizationRatio, uint256 rateSlope1, uint256 rateSlope2) {
        BASE_FEE_RATE = baseFeeRate;
        OPTIMAL_UTILIZATION_RATIO = optimalUtilizationRatio;
        MAX_EXCESS_UTILIZATION_RATIO = 1e18 - optimalUtilizationRatio;
        RATE_SLOPE_1 = rateSlope1;
        RATE_SLOPE_2 = rateSlope2;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IFeeCalculator
    function calculateFee(FC.CalculateFeeParams calldata params)
        external
        view
        override
        returns (uint256 totalFee, uint256 reserveFee)
    {
        FC.CalculateFeeLocalVars memory vars;

        vars.feeRate = BASE_FEE_RATE;
        vars.utilizationRatio =
            Math.mulDiv(params.outstandingLiquidity + params.newLiquidity, 1e18, params.totalLiquidity);

        if (vars.utilizationRatio > OPTIMAL_UTILIZATION_RATIO) {
            // If U > U_optimal, formula is:
            //                                                        U - U_optimal
            // R_fee = BASE_FEE_RATE + RATE_SLOPE_1 + RATE_SLOPE_2 * ----------------
            //                                                        1 - U_optimal
            vars.feeRate += RATE_SLOPE_1
                + Math.mulDiv(RATE_SLOPE_2, vars.utilizationRatio - OPTIMAL_UTILIZATION_RATIO, MAX_EXCESS_UTILIZATION_RATIO);
        } else {
            // Else, formula is:
            //                                             U
            // R_fee = BASE_FEE_RATE + RATE_SLOPE_1 *  -----------
            //                                          U_optimal
            vars.feeRate += Math.mulDiv(RATE_SLOPE_1, vars.utilizationRatio, OPTIMAL_UTILIZATION_RATIO);
        }

        totalFee = Math.mulDiv(vars.feeRate * params.duration, params.newLiquidity, 1e18);
        reserveFee = Math.mulDiv(totalFee, params.reserveFactor, 1e18);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
