// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Errors } from "src/libraries/Errors.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract Withdraw_Unit_Concrete_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });
    }

    function test_RevertWhen_AmountIsZero() external {
        // Run the test.
        uint256 amount = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.StakingRewards_CannotWithdrawZero.selector));
        stakingRewards.withdraw({ amount: amount });
    }

    modifier whenAmountIsNotZero() {
        // Stake tokens.
        rushERC20Mock.mint({ account: users.alice, amount: defaults.STAKING_AMOUNT() });
        rushERC20Mock.approve({ spender: address(stakingRewards), value: defaults.STAKING_AMOUNT() });
        stakingRewards.stake({ amount: defaults.STAKING_AMOUNT() });
        _;
    }

    function test_RevertWhen_AmountIsGreaterThanBalance() external whenAmountIsNotZero {
        // Run the test.
        uint256 amount = defaults.STAKING_AMOUNT() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StakingRewards_InsufficientBalance.selector, defaults.STAKING_AMOUNT(), amount
            )
        );
        stakingRewards.withdraw({ amount: amount });
    }

    function test_WhenAmountIsLessThanOrEqualToBalance() external whenAmountIsNotZero {
        // Expect the relevant event to be emitted.
        uint256 amount = defaults.STAKING_AMOUNT();
        emit Withdrawn({ user: users.alice, amount: amount });

        // Assert the state before the stake.
        uint256 balanceOfStakerBefore = stakingRewards.balanceOf(users.alice);
        assertEq(balanceOfStakerBefore, amount, "balanceOfStakerBefore");
        uint256 totalSupplyBefore = stakingRewards.totalSupply();
        assertEq(totalSupplyBefore, amount, "totalSupplyBefore");
        uint256 tokenBalanceBefore = rushERC20Mock.balanceOf({ account: address(users.alice) });
        assertEq(tokenBalanceBefore, 0, "tokenBalanceBefore");

        // Withdraw the staked tokens.
        stakingRewards.withdraw(amount);

        // Assert that the total supply and balance of the staker were updated correctly.
        uint256 actualBalanceOfStakerAfter = stakingRewards.balanceOf(users.alice);
        uint256 expectedBalanceOfStakerAfter = 0;
        assertEq(actualBalanceOfStakerAfter, expectedBalanceOfStakerAfter, "balanceOfStakerAfter");

        uint256 actualTotalSupplyAfter = stakingRewards.totalSupply();
        uint256 expectedTotalSupplyAfter = 0;
        assertEq(actualTotalSupplyAfter, expectedTotalSupplyAfter, "totalSupplyAfter");

        uint256 actualTokenBalanceAfter = rushERC20Mock.balanceOf({ account: address(users.alice) });
        uint256 expectedTokenBalanceAfter = amount;
        assertEq(actualTokenBalanceAfter, expectedTokenBalanceAfter, "tokenBalanceAfter");
    }
}
