// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract RemoveAdmin_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.removeAdmin(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountDoesNotHaveAdminRole() external whenCallerHasAdminRole {
        // Do nothing.
        vm.recordLogs();
        aclManager.removeAdmin(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountHasAdminRole() external whenCallerHasAdminRole {
        // Grant admin role to account.
        aclManager.addAdmin(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleRevoked({ role: ADMIN_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's admin status before.
        bool expectedIsAdminBefore = aclManager.isAdmin(users.eve);
        assertTrue(expectedIsAdminBefore, "isAdminBefore");

        // Revoke admin role from account.
        aclManager.removeAdmin(users.eve);

        // Assert the account's admin status after.
        bool expectedIsAdminAfter = aclManager.isAdmin(users.eve);
        assertFalse(expectedIsAdminAfter, "isAdminAfter");
    }
}
