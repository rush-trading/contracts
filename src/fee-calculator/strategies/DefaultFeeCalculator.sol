// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ud } from "@prb/math/src/UD60x18.sol";

/**
 * @title DefaultFeeCalculator
 * @notice Calculates liquidity deployment fees.
 */
contract DefaultFeeCalculator {
    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    /**
     * @dev The parameters to calculate the liquidity deployment fee.
     * @param duration The duration of liquidity deployment.
     * @param lastAvailableLiquidity The available liquidity before the new liquidity is deployed.
     * @param lastDeployedLiquidity The liquidity deployed before the new liquidity is deployed.
     * @param newDeployedLiquidity The new liquidity to be deployed.
     * @param reserveFactor The reserve factor of the pool.
     */
    struct CalculateFeeParams {
        uint256 duration;
        uint256 lastAvailableLiquidity;
        uint256 lastDeployedLiquidity;
        uint256 newDeployedLiquidity;
        uint256 reserveFactor;
    }

    /**
     * @dev The local variables to calculate the liquidity deployment fee.
     * @param availablePlusDeployedLiquidity The available liquidity plus the liquidity deployed.
     * @param feeRate The fee rate to be applied.
     * @param utilizationRatio The utilization ratio of the pool.
     */
    struct CalculateFeeLocalVars {
        uint256 availablePlusDeployedLiquidity;
        uint256 feeRate;
        uint256 utilizationRatio;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /**
     * @notice The base fee rate when the utilization ratio is 0.
     * @dev Expressed in 18 decimals.
     */
    uint256 public immutable BASE_FEE_RATE;

    /**
     * @dev The excess utilization ratio above the optimal, equal to `100% - OPTIMAL_UTILIZATION_RATIO`.
     * @dev Expressed in 18 decimals.
     */
    uint256 public immutable MAX_EXCESS_UTILIZATION_RATIO;

    /**
     * @notice The utilization ratio at which the pool aims to obtain most competitive fee rates.
     * @dev Expressed in 18 decimals.
     */
    uint256 public immutable OPTIMAL_UTILIZATION_RATIO;

    /**
     * @notice The slope of the interest rate curve when utilization ratio is > 0 and <= OPTIMAL_UTILIZATION_RATIO.
     * @dev Expressed in 18 decimals.
     */
    uint256 public immutable RATE_SLOPE1;

    /**
     * @notice The slope of the interest rate curve when utilization ratio is > OPTIMAL_UTILIZATION_RATIO.
     * @dev Expressed in 18 decimals.
     */
    uint256 public immutable RATE_SLOPE2;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * Constructor
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

    /**
     * @notice Calculate the liquidity deployment fee based on the given conditions.
     * @dev The fee is calculated in the same token as the liquidity.
     * @param params The parameters to calculate the fee.
     * @return fee The liquidity pool fee to be paid.
     * @return reserveCut The reserve cut of the fee.
     */
    function calculateFee(CalculateFeeParams calldata params) external view returns (uint256 fee, uint256 reserveCut) {
        CalculateFeeLocalVars memory vars;

        vars.feeRate = BASE_FEE_RATE;

        vars.availablePlusDeployedLiquidity = params.lastAvailableLiquidity + params.lastDeployedLiquidity;
        vars.utilizationRatio = (
            ud(params.lastDeployedLiquidity + params.newDeployedLiquidity) / ud(vars.availablePlusDeployedLiquidity)
        ).intoUint256();

        if (vars.utilizationRatio > OPTIMAL_UTILIZATION_RATIO) {
            // If U > U_optimal, formula is:
            //                                                      U - U_optimal
            // R_fee = BASE_FEE_RATE + RATE_SLOPE1 + RATE_SLOPE2 * ---------------
            //                                                      1 - U_optimal
            uint256 excessFeeUtilizationRatio =
                (ud(vars.utilizationRatio - OPTIMAL_UTILIZATION_RATIO) / ud(MAX_EXCESS_UTILIZATION_RATIO)).intoUint256();

            vars.feeRate += RATE_SLOPE1 + (ud(RATE_SLOPE2) * ud(excessFeeUtilizationRatio)).intoUint256();
        } else {
            // Else, formula is:
            //                                             U
            // R_fee = BASE_FEE_RATE + RATE_SLOPE1 *  -----------
            //                                         U_optimal
            vars.feeRate += RATE_SLOPE1 * (ud(vars.utilizationRatio) / ud(OPTIMAL_UTILIZATION_RATIO)).intoUint256();
        }

        fee = (ud(vars.feeRate * params.duration) * ud(params.newDeployedLiquidity)).intoUint256();
        reserveCut = (ud(fee) * ud(params.reserveFactor)).intoUint256();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
