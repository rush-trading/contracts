// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract AddExemption_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
    function setUp() public override {
        RushERC20Taxable_Integration_Shared_Test.setUp();
        initialize({
            name: RUSH_ERC20_NAME,
            symbol: RUSH_ERC20_SYMBOL,
            maxSupply: defaults.RUSH_ERC20_SUPPLY(),
            recipient: users.recipient,
            initialOwner: users.admin,
            initialExemption: address(users.sender),
            initialTaxBasisPoints: defaults.RUSH_ERC20_TAX_BPS()
        });
    }

    function test_RevertWhen_CallerIsNotOwner() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OwnableUnauthorizedAccount.selector, users.eve));
        RushERC20Taxable(address(rushERC20)).addExemption(users.eve);
    }

    modifier whenCallerIsOwner() {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_GivenExemptionAlreadyExists() external whenCallerIsOwner {
        // Add exemption to the set.
        RushERC20Taxable(address(rushERC20)).addExemption(users.eve);

        // Do nothing.
        vm.recordLogs();
        RushERC20Taxable(address(rushERC20)).addExemption(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_GivenExemptionDoesNotExist() external whenCallerIsOwner {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        emit ExemptionAdded({ exemption: users.eve });

        // Add exemption to the set.
        RushERC20Taxable(address(rushERC20)).addExemption(users.eve);

        // Assert the exemption was added correctly.
        address actualExemption = RushERC20Taxable(address(rushERC20)).getExemptedAddresses()[2];
        address expectedExemption = users.eve;
        assertEq(actualExemption, expectedExemption, "exemption");
    }
}
