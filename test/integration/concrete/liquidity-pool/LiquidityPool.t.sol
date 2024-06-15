// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Base_Test } from "test/Base.t.sol";

contract LiquidityPool_Integration_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    function deploy() internal {
        liquidityPool =
            new LiquidityPool({ admin_: users.admin, assetManager_: users.assetManager, weth_: address(weth) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });
    }
}
