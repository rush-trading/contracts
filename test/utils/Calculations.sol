// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.25;

abstract contract Calculations {
    /// @dev Mimics the logic of {FeeCalculator#calculateFee}.
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

    /// @dev Mimics the logic of {UniswapV2Library#getAmountOut}.
    /// @dev
    /// https://github.com/Uniswap/v2-periphery/blob/0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f/contracts/libraries/UniswapV2Library.sol#L43
    function calculateExactAmountOut(
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
