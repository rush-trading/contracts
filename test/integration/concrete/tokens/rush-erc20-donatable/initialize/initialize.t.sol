// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Donatable } from "src/tokens/RushERC20Donatable.sol";
import { RushERC20Donatable_Integration_Shared_Test } from "test/integration/shared/RushERC20Donatable.t.sol";

contract Initialize_Integration_Concrete_Test is RushERC20Donatable_Integration_Shared_Test {
    function test_RevertGiven_AlreadyInitialized() external {
        // Initialize the contract.
        string memory name = RUSH_ERC20_NAME;
        string memory symbol = RUSH_ERC20_SYMBOL;
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        address recipient = users.recipient;
        address donationBeneficiary = users.sender;
        address liquidityDeployer = address(liquidityDeployer);
        address uniV2Pair = users.recipient;
        bytes memory data = abi.encode(donationBeneficiary, liquidityDeployer, uniV2Pair);
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    function test_GivenNotInitialized() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        string memory name = RUSH_ERC20_NAME;
        string memory symbol = RUSH_ERC20_SYMBOL;
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        address recipient = users.recipient;
        address donationBeneficiary = users.sender;
        address liquidityDeployer = address(liquidityDeployer);
        address uniV2Pair = users.recipient;
        bytes memory data = abi.encode(donationBeneficiary, liquidityDeployer, uniV2Pair);

        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });

        // Initialize the contract.
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });

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

        address actualDonationBeneficiary = RushERC20Donatable(address(rushERC20)).donationBeneficiary();
        address expectedDonationBeneficiary = donationBeneficiary;
        assertEq(actualDonationBeneficiary, expectedDonationBeneficiary, "donationBeneficiary");
        address actualLiquidityDeployer = address(RushERC20Donatable(address(rushERC20)).liquidityDeployer());
        address expectedLiquidityDeployer = liquidityDeployer;
        assertEq(actualLiquidityDeployer, expectedLiquidityDeployer, "liquidityDeployer");
        address actualUniV2Pair = RushERC20Donatable(address(rushERC20)).uniV2Pair();
        address expectedUniV2Pair = uniV2Pair;
        assertEq(actualUniV2Pair, expectedUniV2Pair, "uniV2Pair");
    }
}
