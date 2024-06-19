// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    // #region -----------------------------------=|+ GENERICS +|=----------------------------------- //

    /// @notice Thrown when the account is missing a role.
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /// @notice Thrown when the contract is paused.
    error EnforcedPause();

    /// @notice Thrown when the contract is not paused.
    error ExpectedPause();

    /// @notice Thrown when the contract is already initialized.
    error InvalidInitialization();

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ LIQUIDITY-DEPLOYER +|=------------------------------ //

    /**
     * @notice Thrown when the liquidity deployment has already been unwound.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_AlreadyUnwound(address pair);

    /**
     * @notice Thrown when the received deployment fee does not match the expected fee.
     * @param expected The expected fee.
     * @param received The received fee.
     */
    error LiquidityDeployer_FeeMismatch(uint256 expected, uint256 received);

    /**
     * @notice Thrown when the callback sender is invalid.
     * @param sender The address of the callback sender.
     */
    error LiquidityDeployer_InvalidCallbackSender(address sender);

    /**
     * @notice Thrown when a pair has already received liquidity.
     * @param token The address of the deployed token of the pair.
     * @param pair The address of the Uniswap V2 pair that has already received liquidity.
     */
    error LiquidityDeployer_PairAlreadyReceivedLiquidity(address token, address pair);

    /**
     * @notice Thrown when the pair has not received liquidity.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_PairNotReceivedLiquidity(address pair);

    /**
     * @notice Thrown when the pool does not contain the entire supply of the other token.
     * @param token The address of the other token.
     * @param pair The address of the Uniswap V2 pair.
     * @param pairBalance The balance of the deployed token in the pair.
     * @param totalSupply The total supply of the deployed token.
     */
    error LiquidityDeployer_PairSupplyDiscrepancy(address token, address pair, uint256 pairBalance, uint256 totalSupply);

    /**
     * @notice Thrown when liquidity unwinding conditions are not met.
     * @param pair The address of the Uniswap V2 pair.
     * @param deadline The deadline timestamp.
     */
    error LiquidityDeployer_UnwindNotReady(address pair, uint256 deadline);

    /**
     * @notice Thrown when the duration is greater than the maximum limit.
     * @param duration The duration attempted to set.
     */
    error LiquidityDeployer_MaxDuration(uint256 duration);

    /**
     * @notice Thrown when the amount to deploy is greater than the maximum limit.
     * @param amount The amount attempted to deploy.
     */
    error LiquidityDeployer_MaxLiquidtyAmount(uint256 amount);

    /**
     * @notice Thrown when the duration is less than the minimum limit.
     * @param duration The duration attempted to set.
     */
    error LiquidityDeployer_MinDuration(uint256 duration);

    /**
     * @notice Thrown when the amount to deploy is less than the minimum limit.
     * @param amount The amount attempted to deploy.
     */
    error LiquidityDeployer_MinLiquidtyAmount(uint256 amount);

    /**
     * @notice Thrown when the total supply of the deployed token is zero.
     * @param token The address of the deployed token.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_TotalSupplyZero(address token, address pair);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ LIQUIDITY-POOL +|=-------------------------------- //

    /// @notice Thrown when a zero address is provided.
    error LiquidityPool_ZeroAddress();

    /// @notice Thrown when a zero amount is provided.
    error LiquidityPool_ZeroAmount();

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-FACTORY +|=------------------------------ //

    /// @dev Thrown when the implementation does not support the required interface.
    error RushERC20Factory_InvalidInterfaceId();

    /**
     * @dev Thrown when the template does not exist.
     * @param kind The kind of token template.
     */
    error RushERC20Factory_NotTemplate(bytes32 kind);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ RUSH-LAUNCHER +|=--------------------------------- //

    /**
     * @notice Thrown when the maximum supply of the token is too low.
     * @param maxSupply The maximum supply of the token.
     */
    error RushLauncher_LowMaxSupply(uint256 maxSupply);

    // #endregion ----------------------------------------------------------------------------------- //
}
