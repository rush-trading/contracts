// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Rush_ERC20_Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract Version_Integration_Concrete_Test is Rush_ERC20_Taxable_Integration_Shared_Test {
    function test_ShouldReturnCorrectVersion() external view {
        uint256 actualVersion = rushERC20.version();
        uint256 expectedVersion = 1;
        vm.assertEq(actualVersion, expectedVersion, "version");
    }
}
