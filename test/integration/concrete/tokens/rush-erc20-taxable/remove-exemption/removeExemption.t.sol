// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract RemoveExemption_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
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
        RushERC20Taxable(address(rushERC20)).removeExemption(users.eve);
    }

    modifier whenCallerIsOwner() {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_GivenExemptionDoesNotExist() external whenCallerIsOwner {
        // Do nothing.
        vm.recordLogs();
        RushERC20Taxable(address(rushERC20)).removeExemption(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_GivenExemptionExists() external whenCallerIsOwner {
        // Add exchange pool to the set.
        RushERC20Taxable(address(rushERC20)).addExemption(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        emit ExemptionRemoved({ exemption: users.eve });

        // Assert the exchange pool exists.
        address[] memory exemptionsBefore = RushERC20Taxable(address(rushERC20)).getExemptedAddresses();
        assertEq(exemptionsBefore.length, 3, "exemptionsBefore");
        address actualExemptionBefore = exemptionsBefore[2];
        address expectedExemptionBefore = users.eve;
        assertEq(actualExemptionBefore, expectedExemptionBefore, "exemptionBefore");

        // Remove exchange pool from the set.
        RushERC20Taxable(address(rushERC20)).removeExemption(users.eve);

        // Assert the exchange pool was removed correctly.
        address[] memory exemptionsAfter = RushERC20Taxable(address(rushERC20)).getExemptedAddresses();
        assertEq(exemptionsAfter.length, 2, "exemptionAfter");
    }
}
