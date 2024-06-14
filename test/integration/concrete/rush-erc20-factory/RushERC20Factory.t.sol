// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { BadRushERC20Mock } from "test/mocks/BadRushERC20Mock.sol";

import { Base_Test } from "test/Base.t.sol";

contract RushERC20Factory_Integration_Concrete_Test is Base_Test {
    GoodRushERC20Mock internal goodRushERC20Mock;
    BadRushERC20Mock internal badRushERC20Mock;

    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    function deploy() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin, tokenDeployer_: users.tokenDeployer });
        goodRushERC20Mock = new GoodRushERC20Mock();
        badRushERC20Mock = new BadRushERC20Mock();
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
        vm.label({ account: address(goodRushERC20Mock), newLabel: "GoodRushERC20Mock" });
        vm.label({ account: address(badRushERC20Mock), newLabel: "BadRushERC20Mock" });
    }
}
