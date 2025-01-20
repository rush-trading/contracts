// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract RemoveExchangePool_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
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
        RushERC20Taxable(address(rushERC20)).removeExchangePool(users.eve);
    }

    modifier whenCallerIsOwner() {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_GivenExchangePoolDoesNotExist() external whenCallerIsOwner {
        // Do nothing.
        vm.recordLogs();
        RushERC20Taxable(address(rushERC20)).removeExchangePool(users.eve);

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_GivenExchangePoolExists() external whenCallerIsOwner {
        // Add exchange pool to the set.
        RushERC20Taxable(address(rushERC20)).addExchangePool(users.eve);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        emit ExchangePoolRemoved({ exchangePool: users.eve });

        // Assert the exchange pool exists.
        address[] memory exchangePoolsBefore = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        assertEq(exchangePoolsBefore.length, 2, "exchangePoolsBefore");
        address actualExchangePoolBefore = exchangePoolsBefore[1];
        address expectedExchangePoolBefore = users.eve;
        assertEq(actualExchangePoolBefore, expectedExchangePoolBefore, "exchangePoolBefore");

        // Remove exchange pool from the set.
        RushERC20Taxable(address(rushERC20)).removeExchangePool(users.eve);

        // Assert the exchange pool was removed correctly.
        address[] memory exchangePoolsAfter = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        assertEq(exchangePoolsAfter.length, 1, "exchangePoolAfter");
    }
}
