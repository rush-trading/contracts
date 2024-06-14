// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract RemoveTemplate_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // it should revert
    }

    modifier whenCallerHasAdminRole() {
        _;
    }

    function test_RevertWhen_KindIsNotRegistered() external whenCallerHasAdminRole {
        // it should revert
    }

    function test_WhenKindIsRegistered() external whenCallerHasAdminRole {
        // it should remove template
        // it should emit a {RemoveTemplate} event
    }
}
