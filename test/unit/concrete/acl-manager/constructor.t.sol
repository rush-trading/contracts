// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { IACLManager } from "src/interfaces/IACLManager.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_ACLManager_Unit_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Construct the contract.
        IACLManager constructedACLManager = new ACLManager({ admin_: users.admin });

        // Assert that the values were set correctly.
        bool expectedIsAdmin = constructedACLManager.isAdmin(users.admin);
        assertTrue(expectedIsAdmin, "isAdmin");
    }
}
