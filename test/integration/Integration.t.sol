// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    // #region -------------------------------=|+ SET-UP FUNCTION +|=-------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the contracts.
        deployCore();

        // Grant roles.
        grantRolesCore();

        // Approve the contracts.
        approveCore();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
