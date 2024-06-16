// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract CreateERC20_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveTokenDeployerRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        bytes32 kind = defaults.TEMPLATE_KIND();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, TOKEN_DEPLOYER_ROLE)
        );
        rushERC20Factory.createERC20({ kind: kind, originator: users.sender });
    }

    modifier whenCallerHasTokenDeployerRole() {
        // Make TokenDeployer the caller in this test.
        changePrank({ msgSender: users.tokenDeployer });
        _;
    }

    function test_RevertGiven_ImplementationIsNotRegistered() external whenCallerHasTokenDeployerRole {
        // Run the test.
        bytes32 kind = defaults.TEMPLATE_KIND();
        vm.expectRevert();
        rushERC20Factory.createERC20({ kind: kind, originator: users.sender });
    }

    function test_GivenImplementationIsRegistered() external whenCallerHasTokenDeployerRole {
        // Add the template.
        addTemplateToFactory({ implementation: address(goodRushERC20Mock) });

        // Expect the relevant event to be emitted.
        vm.expectEmit({
            emitter: address(rushERC20Factory),
            checkTopic1: true,
            checkTopic2: true,
            checkTopic3: true,
            checkData: false // Ignore `token` field.
         });
        emit CreateERC20({
            originator: users.sender,
            kind: defaults.TEMPLATE_KIND(),
            version: defaults.TEMPLATE_VERSION(),
            token: address(0)
        });

        // Create the ERC20.
        address token = rushERC20Factory.createERC20({ kind: defaults.TEMPLATE_KIND(), originator: users.sender });

        // Assert that the ERC20 was created.
        assertEq(
            IERC165(token).supportsInterface({ interfaceId: type(IRushERC20).interfaceId }), true, "supportsInterface"
        );
    }
}
