// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";

/**
 * @title ILiquidityDeployer
 * @notice A permissioned contract for deploying WETH-backed liquidity to Uniswap V2 pairs.
 */
interface ILiquidityDeployer is IDispatchAssetCallback, IReturnAssetCallback {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when liquidity is deployed to a pair.
     * @param originator The address that originated the request (i.e., the user).
     * @param token The address of the token that will be deployed as liquidity.
     * @param pair The address of the Uniswap V2 pair that will receive liquidity.
     * @param amount The amount of liquidity deployed.
     * @param deadline The deadline timestamp by which the liquidity must be unwound.
     */
    event DeployLiquidity(
        address indexed originator, address indexed token, address indexed pair, uint256 amount, uint256 deadline
    );

    /**
     * @notice Emitted when the contract is paused.
     */
    event Pause();

    /**
     * @notice Emitted when the contract is unpaused.
     */
    event Unpause();

    /**
     * @notice Emitted when liquidity is unwound from a pair.
     * @param pair The address of the Uniswap V2 pair that liquidity was unwound from.
     * @param originator The address that originated the request (i.e., the user).
     * @param amount The amount of liquidity unwound.
     */
    event UnwindLiquidity(address indexed pair, address indexed originator, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct DeployLiquidityLocalVars {
        uint256 totalSupply;
        uint256 pairBalance;
        uint256 reserveFee;
        uint256 totalFee;
        uint256 deadline;
        uint256 excessAmount;
        bool isToken0WETH;
        uint256 reserve0;
        uint256 reserve1;
        uint256 wethReserve;
        uint256 tokenReserve;
        uint256 amountInWithFee;
        uint256 numerator;
        uint256 denominator;
        uint256 amountOut;
    }

    struct LiquidityDeployment {
        address token;
        address originator;
        uint256 amount;
        uint256 deadline;
        bool isUnwound;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Deploy liquidity to a given pair.
     *
     * Requirements:
     * - Can only be called by a liquidity deployer role.
     * - Contract must not be paused.
     * - Pair must not have received liquidity before.
     * - Total supply of the deployed token must be greater than 0.
     * - Pair should contain entire supply of the deployed token.
     * - Amount to deploy must not be less than minimum limit.
     * - Amount to deploy must not be greater than maximum limit.
     * - Duration must not be less than minimum limit.
     * - Duration must not be greater than maximum limit.
     * - `msg.value` must be at least the liquidity deployment fee.
     *
     * Actions:
     * 1. Store the liquidity deployment.
     * 2. Dispatch asset from LiquidityPool to the pair.
     *
     * @param originator The address that originated the request (i.e., the user).
     * @param pair The address of the Uniswap V2 pair that will receive liquidity.
     * @param token The address of the token launched.
     * @param amount The amount of liquidity to deploy.
     * @param duration The duration for which the liquidity will be deployed.
     */
    function deployLiquidity(
        address originator,
        address pair,
        address token,
        uint256 amount,
        uint256 duration
    )
        external
        payable;

    /**
     * @notice Pause the contract.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     */
    function pause() external;

    /**
     * @notice Unpause the contract.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     */
    function unpause() external;

    /**
     * @notice An emergency function to unwind liquidity from given pairs and return it to the LiquidityPool.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     * - Contract must be paused.
     * - Pair must have received liquidity before.
     * - Pair must not have been unwound before.
     *
     * @param pairs The addresses of the Uniswap V2 pairs that liquidity will be unwound from.
     */
    function unwindLiquidityEMERGENCY(address[] calldata pairs) external;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Unwind liquidity from a given pair and return it to the LiquidityPool.
     *
     * Requirements:
     * - Pair must have received liquidity before.
     * - Pair must not have been unwound before.
     * - Deadline must have passed or early unwind threshold must be met.
     *
     * Actions:
     * 1. Set deployment as unwound.
     * 2. Return asset to the LiquidityPool.
     *
     * @param pair The address of the Uniswap V2 pair that liquidity will be unwound from.
     */
    function unwindLiquidity(address pair) external;

    // #endregion ----------------------------------------------------------------------------------- //
}
