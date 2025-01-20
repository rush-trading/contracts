// SPDX-License-Identifier: MIT
// solhint-disable max-line-length
pragma solidity >=0.8.26;

abstract contract Calculations {
    /// @dev Mimics fee calculation logic in {FeeCalculator#calculateFee}.
    function calculateFee(
        uint256 duration,
        uint256 feeRate,
        uint256 newLiquidity,
        uint256 reserveFactor
    )
        internal
        pure
        returns (uint256 totalFee, uint256 reserveFee)
    {
        totalFee = (feeRate * duration * newLiquidity) / 1e18;
        reserveFee = (totalFee * reserveFactor) / 1e18;
    }

    /// @dev Mimics fee rate calculation logic in {FeeCalculator#calculateFeeRate}.
    function calculateFeeRate(
        uint256 baseFeeRate,
        uint256 rateSlope1,
        uint256 rateSlope2,
        uint256 utilizationRatio,
        uint256 optimalUtilizationRatio
    )
        internal
        pure
        returns (uint256 feeRate)
    {
        if (utilizationRatio > optimalUtilizationRatio) {
            // If U > U_optimal, formula is:
            //                                                        U - U_optimal
            // R_fee = BASE_FEE_RATE + RATE_SLOPE_1 + RATE_SLOPE_2 * ----------------
            //                                                        1 - U_optimal
            feeRate = baseFeeRate + rateSlope1
                + (
                    (rateSlope2 * utilizationRatio - rateSlope2 * optimalUtilizationRatio)
                        / (1e18 - optimalUtilizationRatio)
                );
        } else {
            // Else, formula is:
            //                                             U
            // R_fee = BASE_FEE_RATE + RATE_SLOPE_1 *  -----------
            //                                          U_optimal
            feeRate = baseFeeRate + (rateSlope1 * utilizationRatio) / optimalUtilizationRatio;
        }
    }

    /// @dev Mimics the logic of {UniswapV2Library#getAmountOut}.
    /// @dev
    /// https://github.com/Uniswap/v2-periphery/blob/0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f/contracts/libraries/UniswapV2Library.sol#L43
    function calculateAmountOutFromExactIn(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
