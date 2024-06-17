// SPDX-License-Identifier: UNLICENSED
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
}
