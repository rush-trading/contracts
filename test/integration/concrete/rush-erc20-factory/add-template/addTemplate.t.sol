// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract AddTemplate_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        rushERC20Factory.addTemplate({ implementation: address(goodRushERC20Mock) });
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ImplementationDoesNotSupportRequiredInterface() external whenCallerHasAdminRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushERC20Factory_InvalidInterfaceId.selector));
        rushERC20Factory.addTemplate({ implementation: address(badRushERC20Mock) });
    }

    function test_WhenImplementationSupportsRequiredInterface() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20Factory) });
        emit AddTemplate({ kind: templateKind, version: templateVersion, implementation: address(goodRushERC20Mock) });

        // Add the template.
        rushERC20Factory.addTemplate({ implementation: address(goodRushERC20Mock) });

        // Assert that the template was added.
        address actualImplementation = rushERC20Factory.getTemplate(templateKind);
        address expectedImplementation = address(goodRushERC20Mock);
        vm.assertEq(actualImplementation, expectedImplementation, "template");
    }
}
