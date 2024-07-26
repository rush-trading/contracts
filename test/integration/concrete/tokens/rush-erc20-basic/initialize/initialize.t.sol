// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Basic_Integration_Shared_Test } from "test/integration/shared/RushERC20Basic.t.sol";

contract Initialize_Integration_Concrete_Test is RushERC20Basic_Integration_Shared_Test {
    function test_RevertGiven_AlreadyInitialized() external {
        // Initialize the contract.
        string memory name = defaults.RUSH_ERC20_NAME();
        string memory symbol = defaults.RUSH_ERC20_SYMBOL();
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: users.recipient, data: "" });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: users.recipient, data: "" });
    }

    function test_GivenNotInitialized() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        string memory name = defaults.RUSH_ERC20_NAME();
        string memory symbol = defaults.RUSH_ERC20_SYMBOL();
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        address recipient = users.recipient;
        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: "" });

        // Initialize the contract.
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: "" });

        // Assert that the contract was initialized correctly.
        string memory actualName = rushERC20.name();
        string memory expectedName = name;
        assertEq(actualName, expectedName, "name");

        string memory actualSymbol = rushERC20.symbol();
        string memory expectedSymbol = symbol;
        assertEq(actualSymbol, expectedSymbol, "symbol");

        uint256 actualTotalSupply = rushERC20.totalSupply();
        uint256 expectedTotalSupply = maxSupply;
        assertEq(actualTotalSupply, expectedTotalSupply, "totalSupply");

        uint256 actualRecipientBalance = rushERC20.balanceOf({ account: recipient });
        uint256 expectedRecipientBalance = maxSupply;
        assertEq(actualRecipientBalance, expectedRecipientBalance, "balanceOf");
    }
}
