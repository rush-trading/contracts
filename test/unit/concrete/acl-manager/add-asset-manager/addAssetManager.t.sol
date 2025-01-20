// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract AddAssetManager_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.addAssetManager(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountAlreadyHasAssetManagerRole() external whenCallerHasAdminRole {
        // Grant asset manager role to account.
        aclManager.addAssetManager(users.eve);

        // Do nothing.
        vm.recordLogs();
        aclManager.addAssetManager(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountDoesNotHaveAssetManagerRole() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleGranted({ role: ASSET_MANAGER_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's asset manager status before.
        bool expectedIsAssetManagerBefore = aclManager.isAssetManager(users.eve);
        assertFalse(expectedIsAssetManagerBefore, "isAssetManagerBefore");

        // Grant asset manager role to account.
        aclManager.addAssetManager(users.eve);

        // Assert the account's asset manager status after.
        bool expectedIsAssetManagerAfter = aclManager.isAssetManager(users.eve);
        assertTrue(expectedIsAssetManagerAfter, "isAssetManagerAfter");
    }
}
