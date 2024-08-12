// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

/// @notice Contract with default values used throughout the tests.
contract Defaults {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    uint256 public constant BASE_FEE_RATE = 31_709_791_983; // ~100% annual
    uint256 public constant DEPOSIT_AMOUNT = 10 ether; // 10 WETH
    uint256 public constant EARLY_UNWIND_THRESHOLD = 100 ether; // 100 WETH
    uint256 public constant FEE_RATE_U_000 = BASE_FEE_RATE; // U is 0%
    uint256 public constant FEE_RATE_U_OPT = FEE_RATE_U_000 + RATE_SLOPE_1; // U is optimal
    uint256 public constant FEE_RATE_U_100 = FEE_RATE_U_OPT + RATE_SLOPE_2; // U is 100%
    uint256 public constant LIQUIDITY_AMOUNT = 2.75 ether; // 2.75 WETH
    uint256 public constant LIQUIDITY_DURATION = 3 hours;
    uint256 public constant MAX_LIQUIDITY_AMOUNT = 100_000 ether; // 100k WETH
    uint256 public constant MAX_LIQUIDITY_DURATION = 365 days; // 1 year
    uint256 public constant MAX_RUSH_ERC20_SUPPLY = 1_000_000_000_000_000e18; // 1q tokens
    uint256 public constant MAX_TOTAL_LIQUIDITY = 1_000_000_000 ether; // 1b WETH
    uint256 public constant MIN_LIQUIDITY_AMOUNT = 0.00001 ether; // 0.00001 WETH
    uint256 public constant MIN_LIQUIDITY_DURATION = 1 seconds; // 1 seconds
    uint256 public constant MIN_TOTAL_LIQUIDITY = 1 ether; // 1 WETH
    uint256 public constant MIN_RUSH_ERC20_SUPPLY = 0.1e18; // 0.1 tokens
    uint256 public constant OPTIMAL_UTILIZATION_RATIO = 0.6e18; // 60%
    uint256 public constant RATE_SLOPE_1 = 317_097_919; // ~1% annual
    uint256 public constant RATE_SLOPE_2 = 23_782_343_987; // ~75% annual
    uint256 public constant RUSH_ERC20_SUPPLY = 1_000_000_000e18; // 1bn tokens
    uint256 public constant RESERVE_FACTOR = 0.1e18; // 10%
    uint256 public constant ERC20_TAXABLE_RATE_BPS = 500; // 5% tax rate

    // #endregion ----------------------------------------------------------------------------------- //
}
