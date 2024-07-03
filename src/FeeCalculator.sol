// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ud } from "@prb/math/src/UD60x18.sol";

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
    uint256 public immutable override RATE_SLOPE1;

    /// @inheritdoc IFeeCalculator
    uint256 public immutable override RATE_SLOPE2;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param baseFeeRate The base fee rate when the utilization ratio is 0.
     * @param optimalUtilizationRatio The utilization ratio at which the pool aims to obtain most competitive fee rates.
     * @param rateSlope1 The slope of the interest rate curve when utilization ratio is > 0 and <=
     * OPTIMAL_UTILIZATION_RATIO.
     * @param rateSlope2 The slope of the interest rate curve when utilization ratio is > OPTIMAL_UTILIZATION_RATIO.
     */
    constructor(uint256 baseFeeRate, uint256 optimalUtilizationRatio, uint256 rateSlope1, uint256 rateSlope2) {
        BASE_FEE_RATE = baseFeeRate;
        OPTIMAL_UTILIZATION_RATIO = optimalUtilizationRatio;
        MAX_EXCESS_UTILIZATION_RATIO = 1e18 - optimalUtilizationRatio;
        RATE_SLOPE1 = rateSlope1;
        RATE_SLOPE2 = rateSlope2;
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
            (ud(params.outstandingLiquidity + params.newLiquidity) / ud(params.totalLiquidity)).intoUint256();

        if (vars.utilizationRatio > OPTIMAL_UTILIZATION_RATIO) {
            // If U > U_optimal, formula is:
            //                                                      U - U_optimal
            // R_fee = BASE_FEE_RATE + RATE_SLOPE1 + RATE_SLOPE2 * ---------------
            //                                                      1 - U_optimal
            uint256 excessUtilizationRatio =
                (ud(vars.utilizationRatio - OPTIMAL_UTILIZATION_RATIO) / ud(MAX_EXCESS_UTILIZATION_RATIO)).intoUint256();

            vars.feeRate += RATE_SLOPE1 + (ud(RATE_SLOPE2) * ud(excessUtilizationRatio)).intoUint256();
        } else {
            // Else, formula is:
            //                                             U
            // R_fee = BASE_FEE_RATE + RATE_SLOPE1 *  -----------
            //                                         U_optimal
            vars.feeRate +=
                (ud(RATE_SLOPE1) * (ud(vars.utilizationRatio) / ud(OPTIMAL_UTILIZATION_RATIO))).intoUint256();
        }

        totalFee = (ud(vars.feeRate * params.duration) * ud(params.newLiquidity)).intoUint256();
        reserveFee = (ud(totalFee) * ud(params.reserveFactor)).intoUint256();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
