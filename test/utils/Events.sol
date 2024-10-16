// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

/// @notice Abstract contract containing all the events emitted by the protocol.
abstract contract Events {
    // #region -----------------------------------=|+ GENERICS +|=----------------------------------- //

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ RUSH-ERC20 +|=---------------------------------- //

    event Initialize(
        string indexed name, string indexed symbol, uint256 maxSupply, address indexed recipient, bytes data
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-TAXABLE +|=------------------------------ //

    event ExchangePoolAdded(address indexed exchangePool);

    event ExchangePoolRemoved(address indexed exchangePool);

    event ExemptionAdded(address indexed exemption);

    event ExemptionRemoved(address indexed exemption);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ RUSH-ERC20-FACTORY +|=------------------------------ //

    event AddTemplate(bytes32 indexed kind, uint256 indexed version, address implementation);

    event CreateRushERC20(address indexed originator, bytes32 indexed kind, uint256 indexed version, address rushERC20);

    event RemoveTemplate(bytes32 indexed kind, uint256 indexed version);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ RUSH-LAUNCHER +|=--------------------------------- //

    event Launch(
        address indexed rushERC20,
        bytes32 indexed kind,
        address indexed originator,
        address uniV2Pair,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ LIQUIDITY-DEPLOYER +|=------------------------------ //

    event DeployLiquidity(
        address indexed originator,
        address indexed rushERC20,
        address indexed uniV2Pair,
        uint256 amount,
        uint256 totalFee,
        uint256 reserveFee,
        uint256 deadline
    );

    event Pause();

    event SetFeeCalculator(address newFeeCalculator);

    event Unpause();

    event UnwindLiquidity(address indexed uniV2Pair, address indexed originator, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ LIQUIDITY-POOL +|=-------------------------------- //

    event DispatchAsset(address indexed originator, address indexed to, uint256 amount);

    event ReturnAsset(address indexed originator, address indexed from, uint256 amount);

    event SetMaxTotalDeposits(uint256 newMaxTotalDeposits);

    // #endregion ----------------------------------------------------------------------------------- //
}
