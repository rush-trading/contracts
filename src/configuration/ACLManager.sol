// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

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
    bytes32 public constant override LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");

    /// @inheritdoc IACLManager
    bytes32 public constant override RUSH_CREATOR_ROLE = keccak256("RUSH_CREATOR_ROLE");

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
    function isLiquidityDeployer(address account) external view returns (bool) {
        return hasRole(LIQUIDITY_DEPLOYER_ROLE, account);
    }

    /// @inheritdoc IACLManager
    function isRushCreator(address account) external view returns (bool) {
        return hasRole(RUSH_CREATOR_ROLE, account);
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
    function addRushCreator(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: RUSH_CREATOR_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function addLiquidityDeployer(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: account });
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
    function removeLiquidityDeployer(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: account });
    }

    /// @inheritdoc IACLManager
    function removeRushCreator(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole({ role: RUSH_CREATOR_ROLE, account: account });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
