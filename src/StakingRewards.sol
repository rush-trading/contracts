// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IStakingRewards } from "src/interfaces/IStakingRewards.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title StakingRewards
 * @notice See the documentation in {IStakingRewards}.
 */
contract StakingRewards is IStakingRewards, ReentrancyGuardUpgradeable {
    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @inheritdoc IStakingRewards
    mapping(address account => uint256) public override balanceOf;

    /// @inheritdoc IStakingRewards
    uint256 public override lastUpdateTime;

    /// @inheritdoc IStakingRewards
    uint256 public override periodFinish;

    /// @inheritdoc IStakingRewards
    uint256 public override rewardPerTokenStored;

    /// @inheritdoc IStakingRewards
    uint256 public override rewardRate;

    /// @inheritdoc IStakingRewards
    mapping(address account => uint256) public rewards;

    /// @inheritdoc IStakingRewards
    uint256 public override rewardsDuration = 180 days;

    /// @inheritdoc IStakingRewards
    IERC20 public override token;

    /// @inheritdoc IStakingRewards
    uint256 public override totalSupply;

    /// @inheritdoc IStakingRewards
    mapping(address account => uint256) public override userRewardPerTokenPaid;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ MODIFIERS +|=----------------------------------- //

    /// @dev Updates the rewards accrued to an account.
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IStakingRewards
    function earned(address account) public view override returns (uint256) {
        return
            Math.mulDiv(balanceOf[account], rewardPerToken() - userRewardPerTokenPaid[account], 1e18) + rewards[account];
    }

    /// @inheritdoc IStakingRewards
    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /// @inheritdoc IStakingRewards
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /// @inheritdoc IStakingRewards
    function rewardPerToken() public view override returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored
            + Math.mulDiv((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate, 1e18, totalSupply);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /// @inheritdoc IStakingRewards
    function initialize() external override initializer {
        __ReentrancyGuard_init();
        uint256 reward = token.balanceOf(address(this));
        rewardRate = reward / rewardsDuration;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit Initialize(reward);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IStakingRewards
    function exit() external override {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    /// @inheritdoc IStakingRewards
    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            // Effects: Reset the reward for the sender.
            rewards[msg.sender] = 0;

            // Interactions: Transfer the reward to the sender.
            token.transfer(msg.sender, reward);

            // Emit an event.
            emit RewardPaid({ user: msg.sender, reward: reward });
        }
    }

    /// @inheritdoc IStakingRewards
    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        // Checks: Amount must be greater than zero.
        if (amount == 0) {
            revert Errors.StakingRewards_CannotStakeZero();
        }

        // Effects: Update the total supply and the balance of the sender.
        totalSupply = totalSupply + amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] + amount;

        // Interactions: Transfer the tokens from the sender to the contract.
        token.transferFrom(msg.sender, address(this), amount);

        // Emit an event.
        emit Staked({ user: msg.sender, amount: amount });
    }

    /// @inheritdoc IStakingRewards
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        // Checks: Amount must be greater than zero.
        if (amount == 0) {
            revert Errors.StakingRewards_CannotWithdrawZero();
        }

        // Effects: Update the total supply and the balance of the sender.
        totalSupply = totalSupply - amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;

        // Interactions: Transfer the tokens from the contract to the sender.
        token.transfer(msg.sender, amount);

        // Emit an event.
        emit Withdrawn({ user: msg.sender, amount: amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
