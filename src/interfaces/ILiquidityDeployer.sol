// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IACLRoles } from "src/interfaces/IACLRoles.sol";
import { LD } from "src/types/DataTypes.sol";

/**
 * @title ILiquidityDeployer
 * @notice A permissioned contract for deploying WETH-backed liquidity to Uniswap V2 pairs over a specified duration.
 */
interface ILiquidityDeployer is IACLRoles {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when liquidity is deployed to a pair.
     * @param originator The address that originated the request (i.e., the user).
     * @param rushERC20 The address of the RushERC20 token.
     * @param uniV2Pair The address of the Uniswap V2 pair that received liquidity.
     * @param amount The amount of base asset liquidity deployed.
     * @param deadline The timestamp after which the liquidity can be unwound.
     */
    event DeployLiquidity(
        address indexed originator,
        address indexed rushERC20,
        address indexed uniV2Pair,
        uint256 amount,
        uint256 deadline
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
     * @param uniV2Pair The address of the Uniswap V2 pair that liquidity was unwound from.
     * @param originator The address that originated the request (i.e., the user).
     * @param amount The amount of base asset liquidity unwound.
     */
    event UnwindLiquidity(address indexed uniV2Pair, address indexed originator, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The level of base asset liquidity in a Uniswap V2 pair at which early unwinding is allowed.
    function EARLY_UNWIND_THRESHOLD() external view returns (uint256);

    /// @notice The address of the FeeCalculator contract.
    function FEE_CALCULATOR() external view returns (address);

    /// @notice The address of the LiquidityPool contract.
    function LIQUIDITY_POOL() external view returns (address);

    /// @notice The maximum amount of base asset liquidity that can be deployed.
    function MAX_DEPLOYMENT_AMOUNT() external view returns (uint256);

    /// @notice The maximum duration for liquidity deployment.
    function MAX_DURATION() external view returns (uint256);

    /// @notice The minimum amount of base asset liquidity that can be deployed.
    function MIN_DEPLOYMENT_AMOUNT() external view returns (uint256);

    /// @notice The minimum duration for liquidity deployment.
    function MIN_DURATION() external view returns (uint256);

    /// @notice The address of the reserve to which collected fees are sent.
    function RESERVE() external view returns (address);

    /**
     * @notice The reserve factor used for calculating fees.
     * @dev Represented in WAD precision (18 decimal format).
     */
    function RESERVE_FACTOR() external view returns (uint256);

    /// @notice The WETH contract address.
    /// @dev WETH is used as the base asset for liquidity deployment.
    function WETH() external view returns (address);

    /// @notice Retrieves the liquidity deployment entity.
    function getLiquidityDeployment(address uniV2Pair) external view returns (LD.LiquidityDeployment memory);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Deploy liquidity to a given pair.
     *
     * Requirements:
     * - Can only be called by a launcher role.
     * - Contract must not be paused.
     * - Pair must not have received liquidity before.
     * - Total supply of the RushERC20 must be greater than 0.
     * - Pair should hold entire supply of the RushERC20 token.
     * - Amount to deploy must not be less than minimum limit.
     * - Amount to deploy must not be greater than maximum limit.
     * - Duration must not be less than minimum limit.
     * - Duration must not be greater than maximum limit.
     * - `msg.value` must be greater than or equal to the liquidity deployment fee.
     *
     * Actions:
     * 1. Store the liquidity deployment entity.
     * 2. Dispatch asset from LiquidityPool to the Uniswap V2 pair.
     * 3. Convert received fee from ETH to WETH.
     * 4. Transfer reserve fee portion to the pair.
     * 5. Transfer the remaining portion of the fee to the LiquidityPool as APY.
     * 6. Mint LP tokens to the contract.
     * 7. Swap any excess `msg.value` for RushERC20 tokens and return them to the originator.
     *
     * @param originator The address that originated the request (i.e., the user).
     * @param uniV2Pair The address of the Uniswap V2 pair that will receive liquidity.
     * @param rushERC20 The address of the RushERC20 token.
     * @param amount The amount of base asset (i.e., WETH) liquidity to deploy.
     * @param duration The duration over which the liquidity will be deployed (in seconds).
     */
    function deployLiquidity(
        address originator,
        address uniV2Pair,
        address rushERC20,
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
     * @notice An emergency function to unwind liquidity from given Uniswap V2 pairs and return it to the LiquidityPool.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     * - Contract must be paused.
     * - Pairs must have received liquidity before.
     * - Pairs must not have been unwound before.
     *
     * @param uniV2Pairs The addresses of the Uniswap V2 pairs that liquidity will be unwound from.
     */
    function unwindLiquidityEMERGENCY(address[] calldata uniV2Pairs) external;

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
     * 2. Transfer entire LP token balance to the pair.
     * 3. Burn the LP tokens to redeem the underlying assets.
     * 4. Calculate the total reserve fee and the amount of WETH and RushERC20 to lock in the pair.
     * 5. Transfer the WETH to lock to the pair.
     * 6. Transfer the RushERC20 to lock to the pair.
     * 7. Mint LP tokens and send them to a burn address to lock them.
     * 8. Burn entire remaining balance of the RushERC20 token.
     * 9. Transfer the total reserve fee to the reserve.
     * 10. Approve the LiquidityPool to transfer the original liquidity deployment amount.
     * 11. Return asset to the LiquidityPool.
     *
     * @param uniV2Pair The address of the Uniswap V2 pair that liquidity will be unwound from.
     */
    function unwindLiquidity(address uniV2Pair) external;

    // #endregion ----------------------------------------------------------------------------------- //
}
