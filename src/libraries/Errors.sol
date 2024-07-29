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

    // #region ------------------------------------=|+ ROLES +|=------------------------------------- //

    /// @notice Thrown when the account is missing the admin role.
    error OnlyAdminRole(address account);

    /// @notice Thrown when the account is missing the asset manager role.
    error OnlyAssetManagerRole(address account);

    /// @notice Thrown when the account is missing the launcher role.
    error OnlyLauncherRole(address account);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ LIQUIDITY-DEPLOYER +|=------------------------------ //

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
     * @notice Thrown when a pair has already received liquidity.
     * @param rushERC20 The address of the RushERC20 token.
     * @param uniV2Pair The address of the Uniswap V2 pair that has already received liquidity.
     */
    error LiquidityDeployer_PairAlreadyReceivedLiquidity(address rushERC20, address uniV2Pair);

    /**
     * @notice Thrown when the pair has already been unwound.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_PairAlreadyUnwound(address uniV2Pair);

    /**
     * @notice Thrown when the pair has not received liquidity.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_PairNotReceivedLiquidity(address uniV2Pair);

    /**
     * @notice Thrown when the pool does not contain the entire supply of the RushERC20 token.
     * @param rushERC20 The address of the RushERC20 token.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param rushERC20BalanceOfPair The RushERC20 token balance held by the pair.
     * @param rushERC20TotalSupply The total supply of the RushERC20 token.
     */
    error LiquidityDeployer_PairSupplyDiscrepancy(
        address rushERC20, address uniV2Pair, uint256 rushERC20BalanceOfPair, uint256 rushERC20TotalSupply
    );

    /**
     * @notice Thrown when the total supply of the RushERC20 is zero.
     * @param rushERC20 The address of the RushERC20 token.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_TotalSupplyZero(address rushERC20, address uniV2Pair);
    /**
     * @notice Thrown when liquidity unwinding conditions are not met.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param deadline The deadline timestamp.
     * @param currentReserve The current base asset reserve of the pair.
     * @param targetReserve The target base asset reserve of the pair.
     */
    error LiquidityDeployer_UnwindNotReady(
        address uniV2Pair, uint256 deadline, uint256 currentReserve, uint256 targetReserve
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ LIQUIDITY-POOL +|=-------------------------------- //

    /// @notice Thrown when attempting to dispatch assets to the LiquidityPool itself.
    error LiquidityPool_SelfDispatch();

    /// @notice Thrown when attempting to return assets from the LiquidityPool itself.
    error LiquidityPool_SelfReturn();

    /// @notice Thrown when a zero address is provided.
    error LiquidityPool_ZeroAddress();

    /// @notice Thrown when a zero amount is provided.
    error LiquidityPool_ZeroAmount();

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-FACTORY +|=------------------------------ //

    /// @dev Thrown when the token implementation does not support the required interface.
    error RushERC20Factory_InvalidInterfaceId();

    /**
     * @dev Thrown when the token template does not exist.
     * @param kind The kind of RushERC20 token template.
     */
    error RushERC20Factory_NotTemplate(bytes32 kind);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ RUSH-LAUNCHER +|=--------------------------------- //

    /**
     * @notice Thrown when the maximum supply of the token is too high.
     * @param maxSupply The maximum supply of the token.
     */
    error RushLauncher_HighMaxSupply(uint256 maxSupply);

    /**
     * @notice Thrown when the maximum supply of the token is too low.
     * @param maxSupply The maximum supply of the token.
     */
    error RushLauncher_LowMaxSupply(uint256 maxSupply);

    // #endregion ----------------------------------------------------------------------------------- //
}
