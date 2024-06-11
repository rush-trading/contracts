// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { LiquidityDeployer } from "src/liquidity-deployer/LiquidityDeployer.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";

/**
 * @title RushLauncher
 * @notice A permission-less contract for launching ERC20 token markets.
 */
contract RushLauncher {
    // #region --------------------------------=|+ CUSTOM ERRORS +|=--------------------------------- //

    /**
     * @notice Emitted when the maximum supply of the token is too low.
     * @param maxSupply The maximum supply of the token.
     */
    error RushLauncher_LowMaxSupply(uint256 maxSupply);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when a new ERC20 token market is launched.
     * @param token The address of the ERC20 token.
     * @param kind The kind of the ERC20 token template.
     * @param pair The address of the Uniswap V2 pair.
     * @param maxSupply The maximum supply of the ERC20 token.
     * @param liquidityAmount The amount of liquidity deployed.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    event Launch(
        address indexed token,
        bytes32 indexed kind,
        address indexed pair,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    /**
     * @notice The parameters for launching a new ERC20 token market.
     * @param templateDescription The description of the token template.
     * @param name The name of the ERC20 token.
     * @param symbol The symbol of the ERC20 token.
     * @param maxSupply The maximum supply of the ERC20 token.
     * @param data Additional data for the token initialization.
     * @param liquidityAmount The amount of liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    struct LaunchParams {
        string templateDescription;
        string name;
        string symbol;
        uint256 maxSupply;
        bytes data;
        uint256 liquidityAmount;
        uint256 liquidityDuration;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /**
     * @notice The address of the ERC20 factory.
     */
    RushERC20Factory public immutable ERC20_FACTORY;

    /**
     * @notice The address of the liquidity deployer.
     */
    address public immutable LIQUIDITY_DEPLOYER;

    /**
     * @notice The minimum minted supply of the ERC20 token.
     */
    uint256 public immutable MIN_SUPPLY;

    /**
     * @notice The address of the liquidity reserve token.
     */
    address public immutable RESERVE_TOKEN;

    /**
     * @notice The address of the Uniswap V2 factory.
     */
    address public immutable UNISWAP_V2_FACTORY;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param reserveAsset_ The address of the liquidity reserve token.
     * @param erc20Factory_ The address of the ERC20 factory contract.
     * @param uniswapV2Factory_ The address of the Uniswap V2 factory contract.
     * @param liquidityDeployer_ The address of the liquidity deployer contract.
     * @param minSupply_ The minimum minted supply of the ERC20 token.
     */
    constructor(
        address reserveAsset_,
        RushERC20Factory erc20Factory_,
        address uniswapV2Factory_,
        address liquidityDeployer_,
        uint256 minSupply_
    ) {
        RESERVE_TOKEN = reserveAsset_;
        ERC20_FACTORY = erc20Factory_;
        UNISWAP_V2_FACTORY = uniswapV2Factory_;
        LIQUIDITY_DEPLOYER = liquidityDeployer_;
        MIN_SUPPLY = minSupply_;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Launches a new ERC20 token market.
     * @param params The launch parameters.
     */
    function launch(LaunchParams calldata params) external payable {
        // Checks: Maximum supply must be greater than the minimum limit.
        if (params.maxSupply < MIN_SUPPLY) {
            revert RushLauncher_LowMaxSupply(params.maxSupply);
        }

        // Compute the kind of the token template.
        bytes32 kind = keccak256(abi.encodePacked(params.templateDescription));
        // Interactions: Create a new ERC20 token.
        address token = ERC20_FACTORY.createERC20({ originator: msg.sender, kind: kind });
        // Interactions: Create the Uniswap V2 pair.
        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).createPair({ tokenA: token, tokenB: RESERVE_TOKEN });
        // Interactions: Initialize the ERC20 token.
        IRushERC20(token).initialize({
            name: params.name,
            symbol: params.symbol,
            maxSupply: params.maxSupply,
            recipient: pair,
            data: params.data
        });
        // Interactions: Create a new pair and deploy liquidity.
        LiquidityDeployer(LIQUIDITY_DEPLOYER).deployLiquidity{ value: msg.value }({
            originator: msg.sender,
            pair: pair,
            token: token,
            amount: params.liquidityAmount,
            duration: params.liquidityDuration
        });

        // Emit an event.
        emit Launch({
            token: token,
            kind: kind,
            pair: pair,
            maxSupply: params.maxSupply,
            liquidityAmount: params.liquidityAmount,
            liquidityDuration: params.liquidityDuration
        });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
