// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_RushERC20_Unit_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Construct the implementation contract.
        GoodRushERC20Mock constructedRushERC20 = new GoodRushERC20Mock();

        // Expect revert when attempting to initialize the implementation contract.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        constructedRushERC20.initialize("", "", 0, address(0), "");
    }
}
