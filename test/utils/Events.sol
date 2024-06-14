// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @notice Abstract contract containing all the events emitted by the protocol.
abstract contract Events {
    // #region --------------------------------=|+ ACCESS-CONTROL +|=-------------------------------- //

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    // #endregion ----------------------------------------------------------------------------------- //
}
