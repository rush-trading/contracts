// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IACLManager } from "src/interfaces/IACLManager.sol";
import { IACLRoles } from "src/interfaces/IACLRoles.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title ACLRoles
 * @notice See the documentation in {IACLRoles}.
 */
abstract contract ACLRoles is IACLRoles {
    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc IACLRoles
    address public immutable override ACL_MANAGER;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager The address of the ACLManager contract.
     */
    constructor(address aclManager) {
        ACL_MANAGER = aclManager;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ MODIFIERS +|=----------------------------------- //

    /// @dev Enforces admin role.
    modifier onlyAdminRole() {
        if (!IACLManager(ACL_MANAGER).isAdmin(msg.sender)) {
            revert Errors.OnlyAdminRole({ account: msg.sender });
        }
        _;
    }

    /// @dev Enforces asset manager role.
    modifier onlyAssetManagerRole() {
        if (!IACLManager(ACL_MANAGER).isAssetManager(msg.sender)) {
            revert Errors.OnlyAssetManagerRole({ account: msg.sender });
        }
        _;
    }

    /// @dev Enforces launcher role.
    modifier onlyLauncherRole() {
        if (!IACLManager(ACL_MANAGER).isLauncher(msg.sender)) {
            revert Errors.OnlyLauncherRole({ account: msg.sender });
        }
        _;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
