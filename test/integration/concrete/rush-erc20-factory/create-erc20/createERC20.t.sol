// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract CreateERC20_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveTokenDeployerRole() external {
        // it should revert
    }

    modifier whenCallerHasTokenDeployerRole() {
        _;
    }

    function test_RevertGiven_ImplementationIsNotRegistered() external whenCallerHasTokenDeployerRole {
        // it should revert
    }

    function test_GivenImplementationIsRegistered() external whenCallerHasTokenDeployerRole {
        // it should create a new ERC20 token
        // it should emit a {CreateERC20} event
    }
}
