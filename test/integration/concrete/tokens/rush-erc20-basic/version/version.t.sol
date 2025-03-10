// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Basic_Integration_Shared_Test } from "test/integration/shared/RushERC20Basic.t.sol";

contract Version_Integration_Concrete_Test is RushERC20Basic_Integration_Shared_Test {
    function test_ShouldReturnCorrectVersion() external view {
        uint256 actualVersion = rushERC20.version();
        uint256 expectedVersion = 1;
        vm.assertEq(actualVersion, expectedVersion, "version");
    }
}
