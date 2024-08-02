// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Base_Test } from "../Base.t.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    // #region -------------------------------=|+ SET-UP FUNCTION +|=-------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the LiquidityPool.
        liquidityPool = new LiquidityPool({ aclManager_: address(aclManager), asset_: address(wethMock) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });

        // Deploy the core contracts.
        deployCore();

        // Grant roles.
        grantRolesCore();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
