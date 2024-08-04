// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IACLManager } from "src/interfaces/IACLManager.sol";

/**
 * @title ACLManager
 * @notice See the documentation in {IACLManager}.
 */
contract ACLManager is AccessControl, IACLManager {
    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @inheritdoc IACLManager
    bytes32 public constant override ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /// @inheritdoc IACLManager
    bytes32 public constant override ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    /// @inheritdoc IACLManager
    bytes32 public constant override LAUNCHER_ROLE = keccak256("LAUNCHER_ROLE");

    /// @inheritdoc IACLManager
    bytes32 public constant override ROUTER_ROLE = keccak256("ROUTER_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param admin_ The address to grant the admin role.
     */
    constructor(address admin_) {
        _grantRole({ role: ADMIN_ROLE, account: admin_ });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IACLManager
    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    /// @inheritdoc IACLManager
    function isAssetManager(address account) external view returns (bool) {
        return hasRole(ASSET_MANAGER_ROLE, account);
    }

    /// @inheritdoc IACLManager
    function isLauncher(address account) external view returns (bool) {
        return hasRole(LAUNCHER_ROLE, account);
    }

    /// @inheritdoc IACLManager
    function isRouter(address account) external view returns (bool) {
        return hasRole(ROUTER_ROLE, account);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /// @inheritdoc IACLManager
    function addAdmin(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: ADMIN_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function addAssetManager(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: ASSET_MANAGER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function addLauncher(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: LAUNCHER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function addRouter(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: ROUTER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function removeAdmin(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: ADMIN_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function removeAssetManager(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: ASSET_MANAGER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function removeLauncher(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: LAUNCHER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function removeRouter(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: ROUTER_ROLE, account: account });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
