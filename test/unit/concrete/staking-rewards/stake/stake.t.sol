// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract Stake_Unit_Concrete_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
    }

    function test_RevertWhen_AmountIsZero() external {
        // Run the test.
        uint256 amount = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.StakingRewards_CannotStakeZero.selector));
        stakingRewards.stake({ amount: amount });
    }

    function test_WhenAmountIsNotZero() external {
        // Set Sender as the caller.
        resetPrank({ msgSender: users.sender });

        // Mint some tokens to the sender.
        uint256 amount = defaults.STAKING_AMOUNT();
        rushERC20Mock.mint({ account: users.sender, amount: amount });

        // Approve the contract to spend the tokens.
        rushERC20Mock.approve({ spender: address(stakingRewards), value: amount });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(stakingRewards) });
        emit Staked({ user: users.sender, amount: amount });

        // Assert the state before the stake.
        uint256 balanceOfStakerBefore = stakingRewards.balanceOf(users.sender);
        assertEq(balanceOfStakerBefore, 0, "balanceOfStakerBefore");
        uint256 totalSupplyBefore = stakingRewards.totalSupply();
        assertEq(totalSupplyBefore, 0, "totalSupplyBefore");

        // Stake the tokens.
        stakingRewards.stake({ amount: amount });

        // Assert that the total supply and balance of the staker were updated correctly.
        uint256 actualBalanceOfStakerAfter = stakingRewards.balanceOf(users.sender);
        uint256 expectedBalanceOfStakerAfter = amount;
        assertEq(actualBalanceOfStakerAfter, expectedBalanceOfStakerAfter, "balanceOfStakerAfter");

        uint256 actualTotalSupplyAfter = stakingRewards.totalSupply();
        uint256 expectedTotalSupplyAfter = amount;
        assertEq(actualTotalSupplyAfter, expectedTotalSupplyAfter, "totalSupplyAfter");
    }
}
