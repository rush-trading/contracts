// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Vm } from "forge-std/src/Vm.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract GetReward_Unit_Concrete_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });
    }

    function test_WhenRewardIsZero() external {
        // Do nothing.
        vm.recordLogs();
        stakingRewards.getReward();

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenRewardIsGreaterThanZero() external {
        // Stake tokens.
        uint256 amount = defaults.STAKING_AMOUNT();
        rushERC20Mock.mint({ account: users.alice, amount: amount });
        rushERC20Mock.approve({ spender: address(stakingRewards), value: amount });
        stakingRewards.stake({ amount: amount });

        // Fast forward 1 day.
        vm.warp(block.timestamp + 1 days);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(stakingRewards) });
        uint256 rewardForDuration = stakingRewards.rewardRate() * 1 days;
        uint256 totalSupply = stakingRewards.totalSupply();
        uint256 reward = Math.mulDiv(amount, Math.mulDiv(rewardForDuration, 1e18, totalSupply), 1e18);
        emit RewardPaid({ user: users.alice, reward: reward });

        // Get the reward.
        stakingRewards.getReward();

        // Assert the contract state.
        uint256 expectedTokenBalance = reward;
        uint256 actualTokenBalance = rushERC20Mock.balanceOf({ account: users.alice });
        assertEq(actualTokenBalance, expectedTokenBalance, "balanceOf");
        assertEq(stakingRewards.rewards(users.alice), 0, "rewards");
    }
}
