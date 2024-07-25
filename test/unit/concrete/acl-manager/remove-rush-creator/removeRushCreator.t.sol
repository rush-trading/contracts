// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract RemoveRushCreator_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.removeRushCreator(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountDoesNotHaveRushCreatorRole() external whenCallerHasAdminRole {
        // Do nothing.
        vm.recordLogs();
        aclManager.removeRushCreator(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountHasRushCreatorRole() external whenCallerHasAdminRole {
        // Grant rush creator role to account.
        aclManager.addRushCreator(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleRevoked({ role: RUSH_CREATOR_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's rush creator status before.
        bool expectedIsRushCreatorBefore = aclManager.isRushCreator(users.eve);
        assertTrue(expectedIsRushCreatorBefore, "isRushCreatorBefore");

        // Revoke rush creator role from account.
        aclManager.removeRushCreator(users.eve);

        // Assert the account's rush creator status after.
        bool expectedIsRushCreatorAfter = aclManager.isRushCreator(users.eve);
        assertFalse(expectedIsRushCreatorAfter, "isRushCreatorAfter");
    }
}
