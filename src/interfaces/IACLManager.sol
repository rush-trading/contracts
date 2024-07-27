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

    /// @notice The token and liquidity launcher role.
    function LAUNCHER_ROLE() external view returns (bytes32);

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
     * @notice Returns true if the address has the launcher role, false otherwise.
     * @param account The address to check.
     * @return True if the given address has the launcher role, false otherwise.
     */
    function isLauncher(address account) external view returns (bool);

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
     * @notice Adds a new launcher.
     * @param account The address to add as a launcher.
     */
    function addLauncher(address account) external;

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
     * @notice Removes a launcher.
     * @param account The address to remove as a launcher.
     */
    function removeLauncher(address account) external;

    // #endregion ----------------------------------------------------------------------------------- //
}
