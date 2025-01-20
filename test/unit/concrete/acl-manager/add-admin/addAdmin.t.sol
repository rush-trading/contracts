// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract AddAdmin_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.addAdmin(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountAlreadyHasAdminRole() external whenCallerHasAdminRole {
        // Grant admin role to account.
        aclManager.addAdmin(users.eve);

        // Do nothing.
        vm.recordLogs();
        aclManager.addAdmin(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountDoesNotHaveAdminRole() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleGranted({ role: ADMIN_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's admin status before.
        bool expectedIsAdminBefore = aclManager.isAdmin(users.eve);
        assertFalse(expectedIsAdminBefore, "isAdminBefore");

        // Grant admin role to account.
        aclManager.addAdmin(users.eve);

        // Assert the account's admin status after.
        bool expectedIsAdminAfter = aclManager.isAdmin(users.eve);
        assertTrue(expectedIsAdminAfter, "isAdminAfter");
    }
}
