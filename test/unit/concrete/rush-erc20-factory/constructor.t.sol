// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_RushERC20Factory_Unit_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: users.admin, sender: address(this) });

        // Construct the contract.
        RushERC20Factory constructedRushERC20Factory = new RushERC20Factory({ admin_: users.admin });

        // Assert that the admin has been initialized.
        bool actualHasRole = constructedRushERC20Factory.hasRole({ role: DEFAULT_ADMIN_ROLE, account: users.admin });
        bool expectedHasRole = true;
        assertEq(actualHasRole, expectedHasRole, "DEFAULT_ADMIN_ROLE");
    }
}
