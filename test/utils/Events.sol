// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @notice Abstract contract containing all the events emitted by the protocol.
abstract contract Events {
    // #region -----------------------------------=|+ GENERICS +|=----------------------------------- //

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ RUSH-ERC20 +|=---------------------------------- //

    event Initialize(
        string indexed name, string indexed symbol, uint256 maxSupply, address indexed recipient, bytes data
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-FACTORY +|=------------------------------ //

    event AddTemplate(bytes32 indexed kind, uint256 indexed version, address implementation);

    event CreateERC20(address indexed originator, bytes32 indexed kind, uint256 indexed version, address token);

    event RemoveTemplate(bytes32 indexed kind, uint256 indexed version);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ RUSH-LAUNCHER +|=--------------------------------- //

    event Launch(
        address indexed token,
        bytes32 indexed kind,
        address indexed pair,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ LIQUIDITY-DEPLOYER +|=------------------------------ //

    event DeployLiquidity(
        address indexed originator, address indexed token, address indexed pair, uint256 amount, uint256 deadline
    );

    event Pause();

    event Unpause();

    event UnwindLiquidity(address indexed pair, address indexed originator, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ LIQUIDITY-POOL +|=-------------------------------- //

    event DispatchAsset(address indexed originator, address indexed to, uint256 amount);

    event ReturnAsset(address indexed originator, address indexed from, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //
}
