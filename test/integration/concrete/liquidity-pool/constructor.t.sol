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
        LiquidityPool constructedLiquidityPool =
            new LiquidityPool({ admin_: users.admin, assetManager_: users.assetManager, weth_: address(weth) });

        // Assert that the admin has been initialized.
        bool actualHasRole = constructedLiquidityPool.hasRole({ role: DEFAULT_ADMIN_ROLE, account: users.admin });
        bool expectedHasRole = true;
        assertEq(actualHasRole, expectedHasRole, "DEFAULT_ADMIN_ROLE");

        // Assert that the asset manager has been initialized.
        actualHasRole = constructedLiquidityPool.hasRole({ role: ASSET_MANAGER_ROLE, account: users.assetManager });
        expectedHasRole = true;
        assertEq(actualHasRole, expectedHasRole, "ASSET_MANAGER_ROLE");
    }
}
