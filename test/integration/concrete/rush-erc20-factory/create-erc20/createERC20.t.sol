// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract CreateERC20_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveTokenDeployerRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        bytes32 kind = defaults.KIND();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, TOKEN_DEPLOYER_ROLE)
        );
        rushERC20Factory.createERC20({ kind: kind, originator: users.sender });
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
