// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title RushLauncher
 * @notice A permission-less contract for launching ERC20 token markets.
 */
contract RushLauncher {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when a new ERC20 token market is launched.
     * @param rushERC20 The address of the RushERC20 token.
     * @param kind The kind of the ERC20 token template.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param maxSupply The minted maximum supply of the ERC20 token.
     * @param liquidityAmount The amount of base asset liquidity deployed.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    event Launch(
        address indexed rushERC20,
        bytes32 indexed kind,
        address indexed uniV2Pair,
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
     * @param maxSupply The minted maximum supply of the ERC20 token.
     * @param data Additional data for the token initialization.
     * @param liquidityAmount The amount of base asset liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment (in seconds).
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
     * @notice The address of the base asset for liquidity.
     */
    address public immutable BASE_ASSET;

    /**
     * @notice The address of the RushERC20Factory.
     */
    RushERC20Factory public immutable ERC20_FACTORY;

    /**
     * @notice The address of the LiquidityDeployer.
     */
    address public immutable LIQUIDITY_DEPLOYER;

    /**
     * @notice The maximum minted supply of the ERC20 token.
     */
    uint256 public immutable MAX_SUPPLY_LIMIT;

    /**
     * @notice The minimum minted supply of the ERC20 token.
     */
    uint256 public immutable MIN_SUPPLY_LIMIT;

    /**
     * @notice The address of the Uniswap V2 factory.
     */
    address public immutable UNISWAP_V2_FACTORY;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param baseAsset_ The address of the base asset for liquidity.
     * @param erc20Factory_ The address of the RushERC20Factory contract.
     * @param liquidityDeployer_ The address of the LiquidityDeployer contract.
     * @param maxSupplyLimit_ The maximum minted supply of the ERC20 token.
     * @param minSupplyLimit_ The minimum minted supply of the ERC20 token.
     * @param uniswapV2Factory_ The address of the Uniswap V2 factory contract.
     */
    constructor(
        address baseAsset_,
        RushERC20Factory erc20Factory_,
        address liquidityDeployer_,
        uint256 maxSupplyLimit_,
        uint256 minSupplyLimit_,
        address uniswapV2Factory_
    ) {
        BASE_ASSET = baseAsset_;
        ERC20_FACTORY = erc20Factory_;
        LIQUIDITY_DEPLOYER = liquidityDeployer_;
        MAX_SUPPLY_LIMIT = maxSupplyLimit_;
        MIN_SUPPLY_LIMIT = minSupplyLimit_;
        UNISWAP_V2_FACTORY = uniswapV2Factory_;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Launches a new ERC20 token market.
     * @param params The launch parameters.
     */
    function launch(LaunchParams calldata params) external payable returns (address rushERC20, address uniV2Pair) {
        // Checks: Maximum supply must be greater than the minimum limit.
        if (params.maxSupply < MIN_SUPPLY_LIMIT) {
            revert Errors.RushLauncher_LowMaxSupply(params.maxSupply);
        }
        // Checks: Maximum supply must be less than the maximum limit.
        if (params.maxSupply > MAX_SUPPLY_LIMIT) {
            revert Errors.RushLauncher_HighMaxSupply(params.maxSupply);
        }

        // Compute the kind of the token template.
        bytes32 kind = keccak256(abi.encodePacked(params.templateDescription));
        // Interactions: Create a new RushERC20 token.
        rushERC20 = ERC20_FACTORY.createRushERC20({ originator: msg.sender, kind: kind });
        // Interactions: Create the Uniswap V2 pair.
        uniV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).createPair({ tokenA: rushERC20, tokenB: BASE_ASSET });
        // Interactions: Initialize the RushERC20 token.
        IRushERC20(rushERC20).initialize({
            name: params.name,
            symbol: params.symbol,
            maxSupply: params.maxSupply,
            recipient: uniV2Pair,
            data: params.data
        });
        // Interactions: Create a new pair and deploy liquidity.
        ILiquidityDeployer(LIQUIDITY_DEPLOYER).deployLiquidity{ value: msg.value }({
            originator: msg.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20,
            amount: params.liquidityAmount,
            duration: params.liquidityDuration
        });

        // Emit an event.
        emit Launch({
            rushERC20: rushERC20,
            kind: kind,
            uniV2Pair: uniV2Pair,
            maxSupply: params.maxSupply,
            liquidityAmount: params.liquidityAmount,
            liquidityDuration: params.liquidityDuration
        });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
