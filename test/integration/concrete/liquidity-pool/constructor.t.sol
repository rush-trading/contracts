// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_LiquidityPool_Integration_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: users.admin, sender: users.sender });

        // Construct the contract.
        LiquidityPool constructedLiquidityPool = new LiquidityPool({ admin_: users.admin, asset_: address(wethMock) });

        // Assert that the admin has been initialized.
        bool actualHasRole = constructedLiquidityPool.hasRole({ role: DEFAULT_ADMIN_ROLE, account: users.admin });
        bool expectedHasRole = true;
        assertEq(actualHasRole, expectedHasRole, "DEFAULT_ADMIN_ROLE");
    }
}
