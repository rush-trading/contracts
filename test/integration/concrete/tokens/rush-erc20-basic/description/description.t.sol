// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Basic_Integration_Shared_Test } from "test/integration/shared/RushERC20Basic.t.sol";

contract Description_Integration_Concrete_Test is RushERC20Basic_Integration_Shared_Test {
    function test_ShouldReturnCorrectDescription() external view {
        string memory actualDescription = rushERC20.description();
        string memory expectedDescription = "RushERC20Basic";
        vm.assertEq(actualDescription, expectedDescription, "description");
    }
}
