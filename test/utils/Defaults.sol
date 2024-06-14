// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @notice Contract with default values used throughout the tests.
contract Defaults {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    uint256 public constant BASE_FEE_RATE = 1e18; // 100%
    uint256 public constant OPTIMAL_UTILIZATION_RATIO = 0.6e18; // 60%
    uint256 public constant RATE_SLOPE1 = 0.01e18; // 1%
    uint256 public constant RATE_SLOPE2 = 0.75e18; // 75%
    uint256 public constant RESERVE_FACTOR = 0.1e18; // 10%

    // #endregion ----------------------------------------------------------------------------------- //
}
