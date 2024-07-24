// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IACLManager } from "src/interfaces/IACLManager.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title ACLRoles
 * @notice Enforces access control based on roles defined in the ACLManager contract.
 */
contract ACLRoles {
    /// @notice The address of the ACLManager contract.
    address public immutable ACL_MANAGER;

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

    modifier onlyAdminRole() {
        if (!IACLManager(ACL_MANAGER).isAdmin(msg.sender)) {
            revert Errors.OnlyAdminRole({ account: msg.sender });
        }
        _;
    }

    modifier onlyAssetManagerRole() {
        if (!IACLManager(ACL_MANAGER).isAssetManager(msg.sender)) {
            revert Errors.OnlyAssetManagerRole({ account: msg.sender });
        }
        _;
    }

    modifier onlyLiquidityDeployerRole() {
        if (!IACLManager(ACL_MANAGER).isLiquidityDeployer(msg.sender)) {
            revert Errors.OnlyLiquidityDeployerRole({ account: msg.sender });
        }
        _;
    }

    modifier onlyRushCreatorRole() {
        if (!IACLManager(ACL_MANAGER).isRushCreator(msg.sender)) {
            revert Errors.OnlyRushCreatorRole({ account: msg.sender });
        }
        _;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
