// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
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
        bytes memory data = abi.encode(donationBeneficiary, liquidityDeployer);
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    struct Vars {
        string name;
        string symbol;
        uint256 maxSupply;
        address recipient;
        address donationBeneficiary;
        address liquidityDeployer;
        bytes data;
        uint256 donationAmount;
        string actualName;
        string expectedName;
        string actualSymbol;
        string expectedSymbol;
        uint256 actualTotalSupply;
        uint256 expectedTotalSupply;
        uint256 actualRecipientBalance;
        uint256 expectedRecipientBalance;
        address actualDonationBeneficiary;
        address expectedDonationBeneficiary;
        uint256 actualDonationAmount;
        uint256 expectedDonationAmount;
        address actualLiquidityDeployer;
        address expectedLiquidityDeployer;
        address actualUniV2Pair;
        address expectedUniV2Pair;
    }

    function test_GivenNotInitialized() external {
        Vars memory vars;
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        vars.name = RUSH_ERC20_NAME;
        vars.symbol = RUSH_ERC20_SYMBOL;
        vars.maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        vars.recipient = users.recipient;
        vars.donationBeneficiary = users.sender;
        vars.liquidityDeployer = address(liquidityDeployer);
        vars.data = abi.encode(vars.donationBeneficiary, liquidityDeployer);

        emit Initialize({
            name: vars.name,
            symbol: vars.symbol,
            maxSupply: vars.maxSupply,
            recipient: vars.recipient,
            data: vars.data
        });

        // Initialize the contract.
        rushERC20.initialize({
            name: vars.name,
            symbol: vars.symbol,
            maxSupply: vars.maxSupply,
            recipient: vars.recipient,
            data: vars.data
        });

        // Assert that the contract was initialized correctly.
        vars.actualName = rushERC20.name();
        vars.expectedName = vars.name;
        assertEq(vars.actualName, vars.expectedName, "name");

        vars.actualSymbol = rushERC20.symbol();
        vars.expectedSymbol = vars.symbol;
        assertEq(vars.actualSymbol, vars.expectedSymbol, "symbol");

        vars.donationAmount = Math.mulDiv(vars.maxSupply, defaults.RUSH_ERC20_DONATION_FACTOR(), 1e18);

        vars.actualTotalSupply = rushERC20.totalSupply();
        vars.expectedTotalSupply = vars.maxSupply - vars.donationAmount;
        assertEq(vars.actualTotalSupply, vars.expectedTotalSupply, "totalSupply");

        vars.actualRecipientBalance = rushERC20.balanceOf({ account: vars.recipient });
        vars.expectedRecipientBalance = vars.maxSupply - vars.donationAmount;
        assertEq(vars.actualRecipientBalance, vars.expectedRecipientBalance, "balanceOf");

        vars.actualDonationBeneficiary = RushERC20Donatable(address(rushERC20)).donationBeneficiary();
        vars.expectedDonationBeneficiary = vars.donationBeneficiary;
        assertEq(vars.actualDonationBeneficiary, vars.expectedDonationBeneficiary, "donationBeneficiary");

        vars.actualDonationAmount = RushERC20Donatable(address(rushERC20)).donationAmount();
        vars.expectedDonationAmount = vars.donationAmount;
        assertEq(vars.actualDonationAmount, vars.expectedDonationAmount, "donationAmount");

        vars.actualLiquidityDeployer = address(RushERC20Donatable(address(rushERC20)).liquidityDeployer());
        vars.expectedLiquidityDeployer = vars.liquidityDeployer;
        assertEq(vars.actualLiquidityDeployer, vars.expectedLiquidityDeployer, "liquidityDeployer");

        vars.actualUniV2Pair = RushERC20Donatable(address(rushERC20)).uniV2Pair();
        vars.expectedUniV2Pair = users.recipient;
        assertEq(vars.actualUniV2Pair, vars.expectedUniV2Pair, "uniV2Pair");
    }
}
