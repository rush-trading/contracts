// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract RemoveTemplate_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        rushERC20Factory.removeTemplate({ description: templateDescription });
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_KindIsNotRegistered() external whenCallerHasAdminRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushERC20Factory_NotTemplate.selector, templateKind));
        rushERC20Factory.removeTemplate({ description: templateDescription });
    }

    function test_WhenKindIsRegistered() external whenCallerHasAdminRole {
        // Add the template.
        addTemplate({ implementation: address(goodRushERC20Mock) });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20Factory) });
        emit RemoveTemplate({ kind: templateKind, version: templateVersion });

        // Remove the template.
        rushERC20Factory.removeTemplate({ description: templateDescription });

        // Assert that the template was removed.
        address actualImplementation = rushERC20Factory.getTemplate(templateKind);
        address expectedImplementation = address(0);
        vm.assertEq(actualImplementation, expectedImplementation, "template");
    }
}
