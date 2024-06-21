// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    uint256 public constant BASE_FEE_RATE = 31_709_791_983; // ~100% annual
    uint256 public constant DEPOSIT_AMOUNT = 10 ether; // 10 WETH
    // TODO: use calculation instead of hardcoding fee amounts
    uint256 public constant FEE_AMOUNT = 0.0009460973173113 ether;
    uint256 public constant FEE_EXCESS_AMOUNT = 0.00042 ether;
    uint256 public constant DISPATCH_AMOUNT = 2.75 ether; // 2.75 WETH
    uint256 public constant EARLY_UNWIND_THRESHOLD = 10 ether; // 10 WETH
    uint256 public constant FEE_RATE_U_000 = BASE_FEE_RATE; // U is 0%
    uint256 public constant FEE_RATE_U_OPT = FEE_RATE_U_000 + RATE_SLOPE1; // U is optimal
    uint256 public constant FEE_RATE_U_100 = FEE_RATE_U_OPT + RATE_SLOPE2; // U is 100%
    uint256 public constant LIQUIDITY_DURATION = 3 hours;
    uint256 public constant MAX_LIQUIDITY_AMOUNT = 10_000_000_000 ether; // 10B WETH
    uint256 public constant MAX_LIQUIDITY_DURATION = 12_775_000 days; // ~35k years
    uint256 public constant MAX_RATIO = 1e18; // 100%
    uint256 public constant MIN_LIQUIDITY_AMOUNT = 1 ether; // 1 WETH
    uint256 public constant MIN_LIQUIDITY_DURATION = 30 minutes;
    uint256 public constant OPTIMAL_UTILIZATION_RATIO = 0.6e18; // 60%
    uint256 public constant RATE_SLOPE1 = 317_097_919; // ~1% annual
    uint256 public constant RATE_SLOPE2 = 23_782_343_987; // ~75% annual
    uint256 public constant RESERVE_FACTOR = 0.1e18; // 10%
    bytes32 public immutable TEMPLATE_KIND;
    uint256 public immutable TEMPLATE_VERSION;
    string public constant TOKEN_NAME = "GoodRush";
    string public constant TOKEN_SYMBOL = "GR";
    uint256 public constant TOKEN_MAX_SUPPLY = 100_000_000_000e18; // 100B tokens
    uint256 public constant TOKEN_MIN_SUPPLY = 100_000e18; // 100k tokens
    bytes4 public constant UNKNOWN_INTERFACE_ID = 0xdeadbeef;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor() {
        GoodRushERC20Mock tempContract = new GoodRushERC20Mock();
        TEMPLATE_KIND = keccak256(abi.encodePacked(tempContract.description()));
        TEMPLATE_VERSION = tempContract.version();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
