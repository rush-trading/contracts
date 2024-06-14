// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract AddTemplate_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // it should revert
    }

    modifier whenCallerHasAdminRole() {
        _;
    }

    function test_RevertWhen_ImplementationDoesNotSupportRequiredInterface() external whenCallerHasAdminRole {
        // it should revert
    }

    function test_WhenImplementationSupportsRequiredInterface() external whenCallerHasAdminRole {
        // it should add template
        // it should emit a {AddTemplate} event
    }
}
