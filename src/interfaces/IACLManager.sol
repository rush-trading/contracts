// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/**
 * @title IACLManager
 * @notice The protocol's access control list manager.
 */
interface IACLManager {
    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The protocol admin role.
    function ADMIN_ROLE() external view returns (bytes32);

    /// @notice The asset manager role.
    function ASSET_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The liquidity deployer role.
    function LIQUIDITY_DEPLOYER_ROLE() external view returns (bytes32);

    /// @notice The rush creator role.
    function RUSH_CREATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns true if the address has the admin role, false otherwise.
     * @param account The address to check.
     * @return True if the given address has the admin role, false otherwise.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Returns true if the address has the asset manager role, false otherwise.
     * @param account The address to check.
     * @return True if the given address has the asset manager role, false otherwise.
     */
    function isAssetManager(address account) external view returns (bool);

    /**
     * @notice Returns true if the address has the liquidity deployer role, false otherwise.
     * @param account The address to check.
     * @return True if the given address has the liquidity deployer role, false otherwise.
     */
    function isLiquidityDeployer(address account) external view returns (bool);

    /**
     * @notice Returns true if the address has the rush creator role, false otherwise.
     * @param account The address to check.
     * @return True if the given address has the rush creator role, false otherwise.
     */
    function isRushCreator(address account) external view returns (bool);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Adds a new admin.
     * @param account The address to add as an admin.
     */
    function addAdmin(address account) external;

    /**
     * @notice Adds a new asset manager.
     * @param account The address to add as an asset manager.
     */
    function addAssetManager(address account) external;

    /**
     * @notice Adds a new rush creator.
     * @param account The address to add as a rush creator.
     */
    function addRushCreator(address account) external;

    /**
     * @notice Adds a new liquidity deployer.
     * @param account The address to add as a liquidity deployer.
     */
    function addLiquidityDeployer(address account) external;

    /**
     * @notice Removes an admin.
     * @param account The address to remove as an admin.
     */
    function removeAdmin(address account) external;

    /**
     * @notice Removes an asset manager.
     * @param account The address to remove as an asset manager.
     */
    function removeAssetManager(address account) external;

    /**
     * @notice Removes a liquidity deployer.
     * @param account The address to remove as a liquidity deployer.
     */
    function removeLiquidityDeployer(address account) external;

    /**
     * @notice Removes a rush creator.
     * @param account The address to remove as a rush creator.
     */
    function removeRushCreator(address account) external;

    // #endregion ----------------------------------------------------------------------------------- //
}
