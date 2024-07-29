// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Basic_Integration_Shared_Test } from "test/integration/shared/RushERC20Basic.t.sol";

contract Initialize_Integration_Fuzz_Test is RushERC20Basic_Integration_Shared_Test {
    function test_GivenNotInitialized(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        address recipient
    )
        external
    {
        // The recipient must not be the zero address.
        vm.assume(recipient != address(0));

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
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
