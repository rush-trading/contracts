// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { FC } from "src/types/DataTypes.sol";

/**
 * @title IFeeCalculator
 * @notice Calculates liquidity deployment fees.
 */
interface IFeeCalculator {
    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /**
     * @notice The base fee rate when U (the utilization ratio) is 0%.
     * @dev Expressed as a per-second rate in 18 decimals.
     */
    function BASE_FEE_RATE() external view returns (uint256);

    /**
     * @dev The excess utilization ratio above the optimal (i.e., 100% - U_optimal).
     * @dev Expressed in 18 decimals.
     */
    function MAX_EXCESS_UTILIZATION_RATIO() external view returns (uint256);

    /**
     * @notice The utilization ratio at which the pool aims to obtain most competitive fee rates.
     * @dev Expressed in 18 decimals.
     */
    function OPTIMAL_UTILIZATION_RATIO() external view returns (uint256);

    /**
     * @notice The slope of the interest rate curve when U >= 0% and <= U_optimal.
     * @dev Expressed as a per-second rate in 18 decimals.
     */
    function RATE_SLOPE1() external view returns (uint256);

    /**
     * @notice The slope of the interest rate curve when U > U_optimal.
     * @dev Expressed as a per-second rate in 18 decimals.
     */
    function RATE_SLOPE2() external view returns (uint256);

    /**
     * @notice Calculate the liquidity deployment fee based on the given conditions.
     * @dev The fee is calculated in the same token as the liquidity.
     * @param params The parameters to calculate the fee.
     * @return totalFee The total fee to be paid.
     * @return reserveFee The reserve portion of the total fee.
     */
    function calculateFee(FC.CalculateFeeParams calldata params)
        external
        view
        returns (uint256 totalFee, uint256 reserveFee);

    // #endregion ----------------------------------------------------------------------------------- //
}
