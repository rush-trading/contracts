// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    uint256 public constant BASE_FEE_RATE = 1e18; // 100%
    uint256 public constant DEPOSIT_AMOUNT = 10 ether; // 10 WETH
    uint256 public constant DISPATCH_AMOUNT = 2.75 ether; // 2.75 WETH
    uint256 public constant OPTIMAL_UTILIZATION_RATIO = 0.6e18; // 60%
    uint256 public constant RATE_SLOPE1 = 0.01e18; // 1%
    uint256 public constant RATE_SLOPE2 = 0.75e18; // 75%
    uint256 public constant RESERVE_FACTOR = 0.1e18; // 10%
    bytes32 public immutable TEMPLATE_KIND;
    uint256 public immutable TEMPLATE_VERSION;
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
