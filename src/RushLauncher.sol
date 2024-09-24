// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IRushERC20Factory } from "src/RushERC20Factory.sol";
import { RL } from "src/types/DataTypes.sol";

/**
 * @title RushLauncher
 * @notice See the documentation in {IRushLauncher}.
 */
contract RushLauncher is IRushLauncher, ACLRoles {
    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc IRushLauncher
    address public immutable override LIQUIDITY_DEPLOYER;

    /// @inheritdoc IRushLauncher
    uint256 public immutable override MAX_SUPPLY_LIMIT;

    /// @inheritdoc IRushLauncher
    uint256 public immutable override MIN_SUPPLY_LIMIT;

    /// @inheritdoc IRushLauncher
    address public immutable override RUSH_ERC20_FACTORY;

    /// @inheritdoc IRushLauncher
    address public immutable override UNISWAP_V2_FACTORY;

    /// @inheritdoc IRushLauncher
    address public immutable override WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager_ The address of the ACLManager contract.
     * @param liquidityDeployer_ The address of the LiquidityDeployer contract.
     * @param maxSupplyLimit_ The maximum minted supply of the ERC20 token.
     * @param minSupplyLimit_ The minimum minted supply of the ERC20 token.
     * @param rushERC20Factory_ The address of the RushERC20Factory contract.
     * @param uniswapV2Factory_ The address of the Uniswap V2 factory contract.
     */
    constructor(
        address aclManager_,
        address liquidityDeployer_,
        uint256 maxSupplyLimit_,
        uint256 minSupplyLimit_,
        address rushERC20Factory_,
        address uniswapV2Factory_
    )
        ACLRoles(aclManager_)
    {
        WETH = ILiquidityDeployer(liquidityDeployer_).WETH();
        LIQUIDITY_DEPLOYER = liquidityDeployer_;
        MAX_SUPPLY_LIMIT = maxSupplyLimit_;
        MIN_SUPPLY_LIMIT = minSupplyLimit_;
        RUSH_ERC20_FACTORY = rushERC20Factory_;
        UNISWAP_V2_FACTORY = uniswapV2Factory_;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IRushLauncher
    function launch(RL.LaunchParams calldata params)
        external
        payable
        override
        onlyRouterRole
        returns (address rushERC20, address uniV2Pair)
    {
        // Checks: Maximum supply must be greater than the minimum limit.
        if (params.maxSupply < MIN_SUPPLY_LIMIT) {
            revert Errors.RushLauncher_LowMaxSupply(params.maxSupply);
        }
        // Checks: Maximum supply must be less than the maximum limit.
        if (params.maxSupply > MAX_SUPPLY_LIMIT) {
            revert Errors.RushLauncher_HighMaxSupply(params.maxSupply);
        }

        // Interactions: Create a new RushERC20 token.
        rushERC20 =
            IRushERC20Factory(RUSH_ERC20_FACTORY).createRushERC20({ originator: params.originator, kind: params.kind });
        // Interactions: Create the Uniswap V2 pair.
        uniV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair({ tokenA: rushERC20, tokenB: WETH });
        if (uniV2Pair == address(0)) {
            uniV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).createPair({ tokenA: rushERC20, tokenB: WETH });
        }
        // Interactions: Initialize the RushERC20 token.
        IRushERC20(rushERC20).initialize({
            name: params.name,
            symbol: params.symbol,
            maxSupply: params.maxSupply,
            recipient: uniV2Pair,
            data: params.data
        });
        // Interactions: Deploy the liquidity.
        ILiquidityDeployer(LIQUIDITY_DEPLOYER).deployLiquidity{ value: msg.value }({
            originator: params.originator,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20,
            amount: params.liquidityAmount,
            duration: params.liquidityDuration
        });

        // Emit an event.
        emit Launch({
            rushERC20: rushERC20,
            kind: params.kind,
            uniV2Pair: uniV2Pair,
            maxSupply: params.maxSupply,
            liquidityAmount: params.liquidityAmount,
            liquidityDuration: params.liquidityDuration
        });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
