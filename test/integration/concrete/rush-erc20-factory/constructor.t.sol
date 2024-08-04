// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { Base_Test } from "test/Base.t.sol";

contract Constructor_RushERC20Factory_Integration_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Construct the contract.
        RushERC20Factory constructedRushERC20Factory = new RushERC20Factory({ aclManager_: address(aclManager) });

        // Assert that the values were set correctly.
        address actualACLManager = constructedRushERC20Factory.ACL_MANAGER();
        address expectedACLManager = address(aclManager);
        assertEq(actualACLManager, expectedACLManager, "ACL_MANAGER");
    }
}
