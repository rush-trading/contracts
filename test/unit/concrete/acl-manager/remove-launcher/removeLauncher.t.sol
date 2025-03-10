// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract RemoveLauncher_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.removeLauncher(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountDoesNotHaveLauncherRole() external whenCallerHasAdminRole {
        // Do nothing.
        vm.recordLogs();
        aclManager.removeLauncher(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountHasLauncherRole() external whenCallerHasAdminRole {
        // Grant launcher role to account.
        aclManager.addLauncher(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleRevoked({ role: LAUNCHER_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's launcher status before.
        bool expectedIsLauncherBefore = aclManager.isLauncher(users.eve);
        assertTrue(expectedIsLauncherBefore, "isLauncherBefore");

        // Revoke launcher role from account.
        aclManager.removeLauncher(users.eve);

        // Assert the account's launcher status after.
        bool expectedIsLauncherAfter = aclManager.isLauncher(users.eve);
        assertFalse(expectedIsLauncherAfter, "isLauncherAfter");
    }
}
