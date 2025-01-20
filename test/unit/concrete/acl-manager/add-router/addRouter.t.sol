// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract AddLRouter_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.addRouter(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountAlreadyHasRouterRole() external whenCallerHasAdminRole {
        // Grant router role to account.
        aclManager.addRouter(users.eve);

        // Do nothing.
        vm.recordLogs();
        aclManager.addRouter(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountDoesNotHaveRouterRole() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleGranted({ role: ROUTER_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's router status before.
        bool expectedIsRouterBefore = aclManager.isRouter(users.eve);
        assertFalse(expectedIsRouterBefore, "isRouterBefore");

        // Grant router role to account.
        aclManager.addRouter(users.eve);

        // Assert the account's router status after.
        bool expectedIsRouterAfter = aclManager.isRouter(users.eve);
        assertTrue(expectedIsRouterAfter, "isRouterAfter");
    }
}
