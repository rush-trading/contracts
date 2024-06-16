// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Basic_Integration_Concrete_Test } from "../RushERC20Basic.t.sol";

contract Description_Integration_Concrete_Test is RushERC20Basic_Integration_Concrete_Test {
    function test_ShouldReturnCorrectDescription() external view {
        string memory actualDescription = rushERC20.description();
        string memory expectedDescription = "RushERC20Basic";
        vm.assertEq(actualDescription, expectedDescription, "description");
    }
}
