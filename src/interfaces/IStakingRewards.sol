// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IStakingRewards
 * @notice A Synthetix StakingRewards adaptation for staking RushERC20 tokens and earning rewards.
 */
interface IStakingRewards {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when the staking rewards contract is initialized.
     * @param reward The amount of rewards added.
     */
    event Initialize(uint256 reward);

    /**
     * @notice Emitted when a user claims rewards.
     * @param user The address of the user.
     * @param reward The amount of rewards claimed.
     */
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @notice Emitted when a user stakes tokens.
     * @param user The address of the user.
     * @param amount The amount of tokens staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user withdraws staked tokens.
     * @param user The address of the user.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /**
     * @notice The staked token balance of an account.
     * @param account The address to check.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice The rewards earned by an account from the beginning of time up to the current timestamp.
     * @param account The address to check.
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice The rewards that can be earned per staked token for the full duration of the rewards distribution period.
     */
    function getRewardForDuration() external view returns (uint256);

    /**
     * @notice The last timestamp reward accrual can be applied.
     * @dev This is the minimum of the current timestamp and the end of the rewards distribution period.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice The last time any rewards were updated.
     */
    function lastUpdateTime() external view returns (uint256);

    /**
     * @notice The end of the rewards distribution period.
     */
    function periodFinish() external view returns (uint256);

    /**
     * @notice The reward per staked token ratio at the current timestamp.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice The reward per staked token ratio stored at the time of the last account reward update.
     */
    function rewardPerTokenStored() external view returns (uint256);

    /**
     * @notice The reward rate.
     */
    function rewardRate() external view returns (uint256);

    /**
     * @notice The rewards already accredited to an account.
     * @param account The address to check.
     */
    function rewards(address account) external view returns (uint256);

    /**
     * @notice The duration of the rewards distribution period.
     */
    function rewardsDuration() external view returns (uint256);

    /**
     * @notice The token for staking and earning rewards.
     */
    function token() external view returns (IERC20);

    /**
     * @notice The total supply of all staked tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice The reward per staked token ratio that's already accredited to an account.
     * @param account The address to check.
     */
    function userRewardPerTokenPaid(address account) external view returns (uint256);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Withdraw all staked tokens and claim rewards.
     */
    function exit() external;

    /**
     * @notice Claim rewards for caller.
     */
    function getReward() external;

    /**
     * @notice Initializes the staking rewards contract.
     * @dev Handles the one-time setup of staking rewards, and assumes reward tokens are already sent to the contract.
     * @param token_ The address of the token to stake and earn rewards.
     */
    function initialize(address token_) external;

    /**
     * @notice Stake tokens to earn rewards.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Withdraw staked tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external;

    // #endregion ----------------------------------------------------------------------------------- //
}
