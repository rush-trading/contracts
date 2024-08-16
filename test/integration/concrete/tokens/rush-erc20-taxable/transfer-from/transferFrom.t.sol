// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract TransferFrom_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
    function setUp() public override {
        RushERC20Taxable_Integration_Shared_Test.setUp();
        initialize({
            name: RUSH_ERC20_NAME,
            symbol: RUSH_ERC20_SYMBOL,
            maxSupply: defaults.RUSH_ERC20_SUPPLY(),
            recipient: users.alice,
            initialOwner: users.admin,
            initialExemption: address(users.eve),
            initialTaxBasisPoints: defaults.RUSH_ERC20_TAX_BPS()
        });
    }

    function test_WhenSenderIsExempt() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Give tokens to Eve.
        deal({ token: address(rushERC20), to: users.eve, give: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceBefore = rushERC20.balanceOf({ account: users.eve });
        uint256 recipientBalanceBefore = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceBefore = rushERC20.balanceOf({ account: users.admin });

        // Send tokens to Recipient.
        rushERC20.approve({ spender: users.eve, value: defaults.RUSH_ERC20_SUPPLY() });
        rushERC20.transferFrom({ from: users.eve, to: users.recipient, value: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceAfter = rushERC20.balanceOf({ account: users.eve });
        uint256 recipientBalanceAfter = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceAfter = rushERC20.balanceOf({ account: users.admin });

        uint256 taxPaid = 0;

        // Assert the Sender's balance change.
        assertEq(senderBalanceAfter, senderBalanceBefore - defaults.RUSH_ERC20_SUPPLY(), "senderBalance");

        // Assert the Recipient's balance change.
        assertEq(
            recipientBalanceAfter, recipientBalanceBefore + defaults.RUSH_ERC20_SUPPLY() - taxPaid, "recipientBalance"
        );

        // Assert the Tax Benificiary's balance change.
        assertEq(taxBenificiaryBalanceAfter, taxBenificiaryBalanceBefore + taxPaid, "taxBenificiaryBalance");
    }

    modifier whenSenderIsNotExempt() {
        // Set Sender as the caller.
        resetPrank({ msgSender: users.sender });

        // Give tokens to Sender.
        deal({ token: address(rushERC20), to: users.sender, give: defaults.RUSH_ERC20_SUPPLY() });
        _;
    }

    function test_WhenRecipientIsExempt() external whenSenderIsNotExempt {
        uint256 senderBalanceBefore = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceBefore = rushERC20.balanceOf({ account: users.eve });
        uint256 taxBenificiaryBalanceBefore = rushERC20.balanceOf({ account: users.admin });

        // Send tokens to Eve.
        rushERC20.approve({ spender: users.sender, value: defaults.RUSH_ERC20_SUPPLY() });
        rushERC20.transferFrom({ from: users.sender, to: users.eve, value: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceAfter = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceAfter = rushERC20.balanceOf({ account: users.eve });
        uint256 taxBenificiaryBalanceAfter = rushERC20.balanceOf({ account: users.admin });

        uint256 taxPaid = 0;

        // Assert the Sender's balance change.
        assertEq(senderBalanceAfter, senderBalanceBefore - defaults.RUSH_ERC20_SUPPLY(), "senderBalance");

        // Assert the Recipient's balance change.
        assertEq(
            recipientBalanceAfter, recipientBalanceBefore + defaults.RUSH_ERC20_SUPPLY() - taxPaid, "recipientBalance"
        );

        // Assert the Tax Benificiary's balance change.
        assertEq(taxBenificiaryBalanceAfter, taxBenificiaryBalanceBefore + taxPaid, "taxBenificiaryBalance");
    }

    modifier whenRecipientIsNotExempt() {
        _;
    }

    function test_WhenSenderIsExchangePool() external whenSenderIsNotExempt whenRecipientIsNotExempt {
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });

        // Give tokens to Alice.
        deal({ token: address(rushERC20), to: users.alice, give: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceBefore = rushERC20.balanceOf({ account: users.alice });
        uint256 recipientBalanceBefore = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceBefore = rushERC20.balanceOf({ account: users.admin });

        // Send tokens to Recipient.
        rushERC20.approve({ spender: users.alice, value: defaults.RUSH_ERC20_SUPPLY() });
        rushERC20.transferFrom({ from: users.alice, to: users.recipient, value: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceAfter = rushERC20.balanceOf({ account: users.alice });
        uint256 recipientBalanceAfter = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceAfter = rushERC20.balanceOf({ account: users.admin });

        uint256 taxPaid = defaults.RUSH_ERC20_SUPPLY() * defaults.RUSH_ERC20_TAX_BPS() / 10_000;

        // Assert the Sender's balance change.
        assertEq(senderBalanceAfter, senderBalanceBefore - defaults.RUSH_ERC20_SUPPLY(), "senderBalance");

        // Assert the Recipient's balance change.
        assertEq(
            recipientBalanceAfter, recipientBalanceBefore + defaults.RUSH_ERC20_SUPPLY() - taxPaid, "recipientBalance"
        );

        // Assert the Tax Benificiary's balance change.
        assertEq(taxBenificiaryBalanceAfter, taxBenificiaryBalanceBefore + taxPaid, "taxBenificiaryBalance");
    }

    modifier whenSenderIsNotExchangePool() {
        // Set Sender as the caller.
        resetPrank({ msgSender: users.sender });

        // Give tokens to Sender.
        deal({ token: address(rushERC20), to: users.sender, give: defaults.RUSH_ERC20_SUPPLY() });
        _;
    }

    function test_WhenRecipientIsExchangePool()
        external
        whenSenderIsNotExempt
        whenRecipientIsNotExempt
        whenSenderIsNotExchangePool
    {
        uint256 senderBalanceBefore = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceBefore = rushERC20.balanceOf({ account: users.alice });
        uint256 taxBenificiaryBalanceBefore = rushERC20.balanceOf({ account: users.admin });

        // Send tokens to Alice.
        rushERC20.approve({ spender: users.sender, value: defaults.RUSH_ERC20_SUPPLY() });
        rushERC20.transferFrom({ from: users.sender, to: users.alice, value: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceAfter = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceAfter = rushERC20.balanceOf({ account: users.alice });
        uint256 taxBenificiaryBalanceAfter = rushERC20.balanceOf({ account: users.admin });

        uint256 taxPaid = defaults.RUSH_ERC20_SUPPLY() * defaults.RUSH_ERC20_TAX_BPS() / 10_000;

        // Assert the Sender's balance change.
        assertEq(senderBalanceAfter, senderBalanceBefore - defaults.RUSH_ERC20_SUPPLY(), "senderBalance");

        // Assert the Recipient's balance change.
        assertEq(
            recipientBalanceAfter, recipientBalanceBefore + defaults.RUSH_ERC20_SUPPLY() - taxPaid, "recipientBalance"
        );

        // Assert the Tax Benificiary's balance change.
        assertEq(taxBenificiaryBalanceAfter, taxBenificiaryBalanceBefore + taxPaid, "taxBenificiaryBalance");
    }

    function test_WhenRecipientIsNotExchangePool()
        external
        whenSenderIsNotExempt
        whenRecipientIsNotExempt
        whenSenderIsNotExchangePool
    {
        uint256 senderBalanceBefore = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceBefore = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceBefore = rushERC20.balanceOf({ account: users.admin });

        // Send tokens to Recipient.
        rushERC20.approve({ spender: users.sender, value: defaults.RUSH_ERC20_SUPPLY() });
        rushERC20.transferFrom({ from: users.sender, to: users.recipient, value: defaults.RUSH_ERC20_SUPPLY() });

        uint256 senderBalanceAfter = rushERC20.balanceOf({ account: users.sender });
        uint256 recipientBalanceAfter = rushERC20.balanceOf({ account: users.recipient });
        uint256 taxBenificiaryBalanceAfter = rushERC20.balanceOf({ account: users.admin });

        uint256 taxPaid = 0;

        // Assert the Sender's balance change.
        assertEq(senderBalanceAfter, senderBalanceBefore - defaults.RUSH_ERC20_SUPPLY(), "senderBalance");

        // Assert the Recipient's balance change.
        assertEq(
            recipientBalanceAfter, recipientBalanceBefore + defaults.RUSH_ERC20_SUPPLY() - taxPaid, "recipientBalance"
        );

        // Assert the Tax Benificiary's balance change.
        assertEq(taxBenificiaryBalanceAfter, taxBenificiaryBalanceBefore + taxPaid, "taxBenificiaryBalance");
    }
}
