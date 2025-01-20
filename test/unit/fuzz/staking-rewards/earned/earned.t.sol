// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract Earned_Unit_Fuzz_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
    }

    function test_ShouldReturnCorrectEarnedValue(address account, uint256 balanceOf) external {
        balanceOf = bound(balanceOf, 0, defaults.STAKING_AMOUNT());

        // Skip if the account is the zero address.
        if (account == address(0)) {
            return;
        }

        // Mint the balance to the account.
        rushERC20Mock.mint({ account: account, amount: balanceOf });

        // Set account as the caller.
        resetPrank({ msgSender: account });

        if (balanceOf > 0) {
            // Approve the StakingRewards contract to spend the balance.
            rushERC20Mock.approve({ spender: address(stakingRewards), value: balanceOf });

            // Stake the balance.
            stakingRewards.stake({ amount: balanceOf });
        }

        // Assert that the value is correct.
        uint256 expected = Math.mulDiv(
            stakingRewards.balanceOf(account),
            stakingRewards.rewardPerToken() - stakingRewards.userRewardPerTokenPaid(account),
            1e18
        ) + stakingRewards.rewards(account);
        uint256 actual = stakingRewards.earned(account);
        assertEq(actual, expected, "earned");
    }
}
