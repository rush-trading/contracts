// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";

import { Base_Test } from "test/Base.t.sol";

contract RushERC20Factory_Unit_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    function deploy() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
    }
}
