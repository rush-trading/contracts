// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { RushERC20Mock } from "test/mocks/RushERC20Mock.sol";

import { Base_Test } from "test/Base.t.sol";

contract RushERC20Factory_Integration_Concrete_Test is Base_Test {
    RushERC20Mock internal rushERC20Mock;

    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    function deploy() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        rushERC20Mock = new RushERC20Mock();
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
        vm.label({ account: address(rushERC20Mock), newLabel: "RushERC20Mock" });
    }
}
