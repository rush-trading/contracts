// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract RemoveTemplate_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        bytes32 kind = defaults.TEMPLATE_KIND();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, DEFAULT_ADMIN_ROLE)
        );
        rushERC20Factory.removeTemplate({ kind: kind });
    }

    modifier whenCallerHasAdminRole() {
        // Make Admin the caller in this test.
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_KindIsNotRegistered() external whenCallerHasAdminRole {
        // Run the test.
        bytes32 kind = defaults.TEMPLATE_KIND();
        vm.expectRevert(abi.encodeWithSelector(Errors.RushERC20Factory_NotTemplate.selector, defaults.TEMPLATE_KIND()));
        rushERC20Factory.removeTemplate({ kind: kind });
    }

    function test_WhenKindIsRegistered() external whenCallerHasAdminRole {
        // Add the template.
        addTemplateToFactory({ implementation: address(goodRushERC20Mock) });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20Factory) });
        emit RemoveTemplate({ kind: defaults.TEMPLATE_KIND(), version: defaults.TEMPLATE_VERSION() });

        // Remove the template.
        rushERC20Factory.removeTemplate({ kind: defaults.TEMPLATE_KIND() });

        // Assert that the template was removed.
        address actualTemplate = rushERC20Factory.templates(defaults.TEMPLATE_KIND());
        address expectedTemplate = address(0);
        vm.assertEq(actualTemplate, expectedTemplate, "template");
    }
}
