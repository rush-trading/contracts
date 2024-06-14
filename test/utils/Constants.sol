// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

abstract contract Constants {
    uint256 internal constant DEFAULT_BASE_FEE_RATE = 1e18; // 100%
    uint256 internal constant DEFAULT_OPTIMAL_UTILIZATION_RATIO = 0.6e18; // 60%
    uint256 internal constant DEFAULT_RATE_SLOPE1 = 0.01e18; // 1%
    uint256 internal constant DEFAULT_RATE_SLOPE2 = 0.75e18; // 75%
}
