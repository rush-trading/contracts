// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

/**
 * @title IACLRoles
 * @notice Enforces ACL roles for any inheriting contract.
 */
interface IACLRoles {
    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The address of the ACLManager contract.
    function ACL_MANAGER() external view returns (address);

    // #endregion ----------------------------------------------------------------------------------- //
}
