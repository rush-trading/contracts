// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Factory_Integration_Concrete_Test } from "../RushERC20Factory.t.sol";

contract CreateRushERC20_Integration_Concrete_Test is RushERC20Factory_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveLauncherRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyLauncherRole.selector, users.eve));
        rushERC20Factory.createRushERC20({ kind: templateKind, originator: users.sender });
    }

    modifier whenCallerHasLauncherRole() {
        // Make Launcher the caller in this test.
        resetPrank({ msgSender: users.launcher });
        _;
    }

    function test_RevertGiven_ImplementationIsNotRegistered() external whenCallerHasLauncherRole {
        // Run the test.
        vm.expectRevert();
        rushERC20Factory.createRushERC20({ kind: templateKind, originator: users.sender });
    }

    function test_GivenImplementationIsRegistered() external whenCallerHasLauncherRole {
        // Add the template.
        addTemplate({ implementation: address(goodRushERC20Mock) });

        // Expect the relevant event to be emitted.
        vm.expectEmit({
            emitter: address(rushERC20Factory),
            checkTopic1: true,
            checkTopic2: true,
            checkTopic3: true,
            checkData: false // Ignore `rushERC20` field.
         });
        emit CreateRushERC20({
            originator: users.sender,
            kind: templateKind,
            version: templateVersion,
            rushERC20: address(0)
        });

        // Create the RushERC20 token.
        address rushERC20 = rushERC20Factory.createRushERC20({ kind: templateKind, originator: users.sender });

        // Assert that the RushERC20 was created.
        assertEq(
            IERC165(rushERC20).supportsInterface({ interfaceId: type(IRushERC20).interfaceId }),
            true,
            "supportsInterface"
        );
    }
}
