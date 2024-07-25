// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ACLManager_Unit_Concrete_Test } from "../ACLManager.t.sol";

contract RemoveLiquidityDeployer_Unit_Concrete_Test is ACLManager_Unit_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ADMIN_ROLE));
        aclManager.removeLiquidityDeployer(users.eve);
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_WhenAccountDoesNotHaveLiquidityDeployerRole() external whenCallerHasAdminRole {
        // Do nothing.
        vm.recordLogs();
        aclManager.removeLiquidityDeployer(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenAccountHasLiquidityDeployerRole() external whenCallerHasAdminRole {
        // Grant liquidity deployer role to account.
        aclManager.addLiquidityDeployer(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(aclManager) });
        emit RoleRevoked({ role: LIQUIDITY_DEPLOYER_ROLE, account: users.eve, sender: users.admin });

        // Assert the account's liquidity deployer status before.
        bool expectedIsLiquidityDeployerBefore = aclManager.isLiquidityDeployer(users.eve);
        assertTrue(expectedIsLiquidityDeployerBefore, "isLiquidityDeployerBefore");

        // Revoke liquidity deployer role from account.
        aclManager.removeLiquidityDeployer(users.eve);

        // Assert the account's liquidity deployer status after.
        bool expectedIsLiquidityDeployerAfter = aclManager.isLiquidityDeployer(users.eve);
        assertFalse(expectedIsLiquidityDeployerAfter, "isLiquidityDeployerAfter");
    }
}
