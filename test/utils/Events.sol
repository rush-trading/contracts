// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @notice Abstract contract containing all the events emitted by the protocol.
abstract contract Events {
    // #region -----------------------------------=|+ GENERICS +|=----------------------------------- //

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-FACTORY +|=------------------------------ //

    event AddTemplate(bytes32 indexed kind, uint256 indexed version, address implementation);

    event CreateERC20(address indexed originator, bytes32 indexed kind, uint256 indexed version, address token);

    event RemoveTemplate(bytes32 indexed kind, uint256 indexed version);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ LIQUIDITY-POOL +|=-------------------------------- //

    event DispatchAsset(address indexed originator, address indexed to, uint256 amount);

    event ReturnAsset(address indexed originator, address indexed from, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //
}
