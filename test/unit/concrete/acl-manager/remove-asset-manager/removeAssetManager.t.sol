// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract RemoveAssetManager_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.removeAssetManager(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountDoesNotHaveAssetManagerRole() external whenCallerHasAdminRole {
        // Do nothing.
        vm.recordLogs();
        aclManager.removeAssetManager(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountHasAssetManagerRole() external whenCallerHasAdminRole {
        // Grant asset manager role to account.
        aclManager.addAssetManager(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleRevoked({ role: ASSET_MANAGER_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's asset manager status before.
        bool expectedIsAssetManagerBefore = aclManager.isAssetManager(users.eve);
        assertTrue(expectedIsAssetManagerBefore, "isAssetManagerBefore");

        // Revoke asset manager role from account.
        aclManager.removeAssetManager(users.eve);

        // Assert the account's asset manager status after.
        bool expectedIsAssetManagerAfter = aclManager.isAssetManager(users.eve);
        assertFalse(expectedIsAssetManagerAfter, "isAssetManagerAfter");
    }
}
