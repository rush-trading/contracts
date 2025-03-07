// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract Description_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
    function test_ShouldReturnCorrectDescription() external view {
        string memory actualDescription = rushERC20.description();
        string memory expectedDescription = "RushERC20Taxable";
        vm.assertEq(actualDescription, expectedDescription, "description");
    }
}
