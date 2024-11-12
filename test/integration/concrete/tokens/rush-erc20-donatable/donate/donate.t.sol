// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Vm } from "forge-std/src/Vm.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Donatable } from "src/tokens/RushERC20Donatable.sol";
import { RushERC20Donatable_Integration_Shared_Test } from "test/integration/shared/RushERC20Donatable.t.sol";

contract Donate_Integration_Concrete_Test is RushERC20Donatable_Integration_Shared_Test {
    function setUp() public override {
        RushERC20Donatable_Integration_Shared_Test.setUp();
        initialize({
            name: RUSH_ERC20_NAME,
            symbol: RUSH_ERC20_SYMBOL,
            maxSupply: defaults.RUSH_ERC20_SUPPLY(),
            recipient: users.recipient,
            donationBeneficiary: users.sender,
            liquidityDeployer: address(liquidityDeployerMock),
            uniV2Pair: users.recipient
        });
    }

    function test_RevertWhen_DeploymentIsNotYetUnwound() external {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC20DonatableUpgradeable_PairNotUnwound.selector));
        RushERC20Donatable(address(rushERC20)).donate();
    }

    modifier whenDeploymentIsUnwound() {
        liquidityDeployerMock.setIsUnwound(users.recipient, true);
        _;
    }

    function test_RevertWhen_DonationWasAlreadySent() external whenDeploymentIsUnwound {
        // Send the donation.
        RushERC20Donatable(address(rushERC20)).donate();

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC20DonatableUpgradeable_AlreadyExecuted.selector));
        RushERC20Donatable(address(rushERC20)).donate();
    }

    modifier whenDonationWasNotYetSent() {
        _;
    }

    function test_WhenUnwindThresholdWasMet() external whenDeploymentIsUnwound whenDonationWasNotYetSent {
        // Set the unwind threshold to be met.
        liquidityDeployerMock.setIsUnwindThresholdMet(users.recipient, true);

        uint256 expectedDonationAmount = defaults.RUSH_ERC20_SUPPLY() / 10;

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        emit DonationSent({ receiver: users.sender, amount: expectedDonationAmount });

        // Assert the state before the donation was sent.
        assertFalse(RushERC20Donatable(address(rushERC20)).isExecuted(), "isExecuted");
        uint256 expectedBalanceOfBeneficiaryBefore = 0;
        uint256 actualBalanceOfBeneficiaryBefore = rushERC20.balanceOf({ account: users.sender });
        assertEq(actualBalanceOfBeneficiaryBefore, expectedBalanceOfBeneficiaryBefore, "balanceOf");

        uint256 expectedTotalSupplyBefore = defaults.RUSH_ERC20_SUPPLY() - expectedDonationAmount;
        uint256 actualTotalSupplyBefore = rushERC20.totalSupply();
        assertEq(actualTotalSupplyBefore, expectedTotalSupplyBefore, "totalSupply");

        // Send the donation.
        RushERC20Donatable(address(rushERC20)).donate();

        // Assert the donation was sent correctly.
        assertTrue(RushERC20Donatable(address(rushERC20)).isExecuted(), "isExecuted");
        uint256 expectedBalanceOfBeneficiaryAfter = expectedDonationAmount;
        uint256 actualBalanceOfBeneficiaryAfter = rushERC20.balanceOf({ account: users.sender });
        assertEq(actualBalanceOfBeneficiaryAfter, expectedBalanceOfBeneficiaryAfter, "balanceOf");

        uint256 expectedTotalSupplyAfter = defaults.RUSH_ERC20_SUPPLY();
        uint256 actualTotalSupplyAfter = rushERC20.totalSupply();
        assertEq(actualTotalSupplyAfter, expectedTotalSupplyAfter, "totalSupply");
    }

    function test_WhenUnwindThresholdWasNotMet() external whenDeploymentIsUnwound whenDonationWasNotYetSent {
        uint256 expectedDonationAmount = defaults.RUSH_ERC20_SUPPLY() / 10;

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushERC20) });
        emit DonationBurned({ amount: expectedDonationAmount });

        // Assert the state before the donation was executed.
        assertFalse(RushERC20Donatable(address(rushERC20)).isExecuted(), "isExecuted");
        uint256 expectedBalanceOfBeneficiaryBefore = 0;
        uint256 actualBalanceOfBeneficiaryBefore = rushERC20.balanceOf({ account: users.sender });
        assertEq(actualBalanceOfBeneficiaryBefore, expectedBalanceOfBeneficiaryBefore, "balanceOf");

        uint256 expectedTotalSupplyBefore = defaults.RUSH_ERC20_SUPPLY() - expectedDonationAmount;
        uint256 actualTotalSupplyBefore = rushERC20.totalSupply();
        assertEq(actualTotalSupplyBefore, expectedTotalSupplyBefore, "totalSupply");

        // Execute the donation.
        RushERC20Donatable(address(rushERC20)).donate();

        // Assert the donation was burned correctly.
        assertTrue(RushERC20Donatable(address(rushERC20)).isExecuted(), "isExecuted");
        uint256 expectedBalanceOfBeneficiaryAfter = 0;
        uint256 actualBalanceOfBeneficiaryAfter = rushERC20.balanceOf({ account: users.sender });
        assertEq(actualBalanceOfBeneficiaryAfter, expectedBalanceOfBeneficiaryAfter, "balanceOf");

        uint256 expectedBurnedDonation = expectedDonationAmount;
        uint256 actualBurnedDonation = rushERC20.balanceOf({ account: address(rushERC20) });
        assertEq(actualBurnedDonation, expectedBurnedDonation, "balanceOf");

        uint256 expectedTotalSupplyAfter = defaults.RUSH_ERC20_SUPPLY();
        uint256 actualTotalSupplyAfter = rushERC20.totalSupply();
        assertEq(actualTotalSupplyAfter, expectedTotalSupplyAfter, "totalSupply");
    }
}
