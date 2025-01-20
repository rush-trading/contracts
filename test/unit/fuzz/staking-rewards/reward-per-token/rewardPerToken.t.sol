// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract RewardPerToken_Unit_Fuzz_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });
    }

    function test_ShouldReturnCorrectRewardPerTokenValue(uint256 totalSupply) external {
        totalSupply = bound(totalSupply, 0, defaults.STAKING_AMOUNT());

        if (totalSupply > 0) {
            // Mint the totalSupply to the account.
            rushERC20Mock.mint({ account: users.alice, amount: totalSupply });

            // Stake the totalSupply.
            rushERC20Mock.approve({ spender: address(stakingRewards), value: totalSupply });
            stakingRewards.stake({ amount: totalSupply });

            // Assert that the value is correct.
            uint256 expected = stakingRewards.rewardPerTokenStored()
                + Math.mulDiv(
                    (stakingRewards.lastTimeRewardApplicable() - stakingRewards.lastUpdateTime())
                        * stakingRewards.rewardRate(),
                    1e18,
                    stakingRewards.totalSupply()
                );
            uint256 actual = stakingRewards.rewardPerToken();
            assertEq(actual, expected, "rewardPerToken");
        } else {
            // Assert that the value is correct.
            uint256 expected = stakingRewards.rewardPerTokenStored();
            uint256 actual = stakingRewards.rewardPerToken();
            assertEq(actual, expected, "rewardPerToken");
        }
    }
}
