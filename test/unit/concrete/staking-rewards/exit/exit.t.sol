// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Errors } from "src/libraries/Errors.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract Exit_Unit_Concrete_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });
    }

    function test_RevertWhen_BalanceIsZero() external {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.StakingRewards_CannotWithdrawZero.selector));
        stakingRewards.exit();
    }

    function test_WhenBalanceIsNotZero() external {
        // Stake tokens.
        uint256 amount = defaults.STAKING_AMOUNT();
        rushERC20Mock.mint({ account: users.alice, amount: amount });
        rushERC20Mock.approve({ spender: address(stakingRewards), value: amount });
        stakingRewards.stake({ amount: amount });

        // Fast forward 1 day.
        vm.warp(block.timestamp + 1 days);

        // Expect the relevant events to be emitted.
        emit Withdrawn({ user: users.alice, amount: amount });

        vm.expectEmit({ emitter: address(stakingRewards) });
        uint256 rewardForDuration = stakingRewards.rewardRate() * 1 days;
        uint256 totalSupply = stakingRewards.totalSupply();
        uint256 reward = Math.mulDiv(amount, Math.mulDiv(rewardForDuration, 1e18, totalSupply), 1e18);
        emit RewardPaid({ user: users.alice, reward: reward });

        // Assert the state before the stake.
        uint256 balanceOfStakerBefore = stakingRewards.balanceOf(users.alice);
        assertEq(balanceOfStakerBefore, amount, "balanceOfStakerBefore");
        uint256 totalSupplyBefore = stakingRewards.totalSupply();
        assertEq(totalSupplyBefore, amount, "totalSupplyBefore");
        uint256 tokenBalanceBefore = rushERC20Mock.balanceOf({ account: address(users.alice) });
        assertEq(tokenBalanceBefore, 0, "tokenBalanceBefore");

        // Exit the staking rewards.
        stakingRewards.exit();

        // Assert that the total supply and balance of the staker were updated correctly.
        uint256 actualBalanceOfStakerAfter = stakingRewards.balanceOf(users.alice);
        uint256 expectedBalanceOfStakerAfter = 0;
        assertEq(actualBalanceOfStakerAfter, expectedBalanceOfStakerAfter, "balanceOfStakerAfter");

        uint256 actualTotalSupplyAfter = stakingRewards.totalSupply();
        uint256 expectedTotalSupplyAfter = 0;
        assertEq(actualTotalSupplyAfter, expectedTotalSupplyAfter, "totalSupplyAfter");

        uint256 actualTokenBalanceAfter = rushERC20Mock.balanceOf({ account: address(users.alice) });
        uint256 expectedTokenBalanceAfter = amount + reward;
        assertEq(actualTokenBalanceAfter, expectedTokenBalanceAfter, "tokenBalanceAfter");

        assertEq(stakingRewards.rewards(users.alice), 0, "rewards");
    }
}
