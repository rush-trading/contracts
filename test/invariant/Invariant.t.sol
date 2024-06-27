// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all invariant tests.
abstract contract Invariant_Test is Base_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
