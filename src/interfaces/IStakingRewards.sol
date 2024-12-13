// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IStakingRewards
 * @notice A contract for staking RushERC20 tokens to earn rewards.
 */
interface IStakingRewards {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

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
     * @notice The staking balance of an account.
     * @param account The address to check.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice The rewards earned by an account.
     * @param account The address to check.
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice The rewards earned by an account for the duration.
     */
    function getRewardForDuration() external view returns (uint256);

    /**
     * @notice The rewards earned by an account.
     * @param account The address to check.
     */
    function rewards(address account) external view returns (uint256);

    /**
     * @notice The last time the rewards were applicable.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice The last time the rewards were updated.
     */
    function lastUpdateTime() external view returns (uint256);

    /**
     * @notice The end of the rewards period.
     */
    function periodFinish() external view returns (uint256);

    /**
     * @notice The duration of the rewards period.
     */
    function rewardsDuration() external view returns (uint256);

    /**
     * @notice The reward per token.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice The reward per token stored.
     */
    function rewardPerTokenStored() external view returns (uint256);

    /**
     * @notice The reward rate.
     */
    function rewardRate() external view returns (uint256);

    /**
     * @notice The token for staking and earning rewards.
     */
    function token() external view returns (IERC20);

    /**
     * @notice The total supply of all staked tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice The reward per token paid to an account.
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
