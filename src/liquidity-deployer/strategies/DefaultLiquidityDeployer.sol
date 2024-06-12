// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IWETH } from "src/external/IWETH.sol";
import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { DefaultFeeCalculator as FeeCalculator } from "src/fee-calculator/strategies/DefaultFeeCalculator.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";

/**
 * @title DefaultLiquidityDeployer
 * @notice A permissioned liquidity deployment contract.
 */
contract DefaultLiquidityDeployer is AccessControl, Pausable, IDispatchAssetCallback, IReturnAssetCallback {
    // #region --------------------------------=|+ CUSTOM ERRORS +|=--------------------------------- //

    /**
     * @notice Emitted when the liquidity deployment has already been unwound.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_AlreadyUnwound(address pair);

    /**
     * @notice Emitted when the received deployment fee does not match the expected fee.
     * @param expected The expected fee.
     * @param received The received fee.
     */
    error LiquidityDeployer_FeeMismatch(uint256 expected, uint256 received);

    /**
     * @notice Emitted when the callback sender is invalid.
     * @param sender The address of the callback sender.
     */
    error LiquidityDeployer_InvalidCallbackSender(address sender);

    /**
     * @notice Emitted when a pair has already received liquidity.
     * @param token The address of the deployed token of the pair.
     * @param pair The address of the Uniswap V2 pair that has already received liquidity.
     */
    error LiquidityDeployer_PairAlreadyReceivedLiquidity(address token, address pair);

    /**
     * @notice Emitted when the pair has not received liquidity.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_PairNotReceivedLiquidity(address pair);

    /**
     * @notice Emitted when the pool does not contain the entire supply of the other token.
     * @param token The address of the other token.
     * @param pair The address of the Uniswap V2 pair.
     * @param pairBalance The balance of the deployed token in the pair.
     * @param totalSupply The total supply of the deployed token.
     */
    error LiquidityDeployer_PairSupplyDiscrepancy(address token, address pair, uint256 pairBalance, uint256 totalSupply);

    /**
     * @notice Emitted when liquidity unwinding conditions are not met.
     * @param pair The address of the Uniswap V2 pair.
     * @param deadline The deadline timestamp.
     */
    error LiquidityDeployer_UnwindNotReady(address pair, uint256 deadline);

    /**
     * @notice Emitted when the duration is greater than the maximum limit.
     * @param duration The duration attempted to set.
     */
    error LiquidityDeployer_MaxDuration(uint256 duration);

    /**
     * @notice Emitted when the amount to deploy is greater than the maximum limit.
     * @param amount The amount attempted to deploy.
     */
    error LiquidityDeployer_MaxLiquidtyAmount(uint256 amount);

    /**
     * @notice Emitted when the duration is less than the minimum limit.
     * @param duration The duration attempted to set.
     */
    error LiquidityDeployer_MinDuration(uint256 duration);

    /**
     * @notice Emitted when the amount to deploy is less than the minimum limit.
     * @param amount The amount attempted to deploy.
     */
    error LiquidityDeployer_MinLiquidtyAmount(uint256 amount);

    /**
     * @notice Emitted when the total supply of the deployed token is zero.
     * @param token The address of the deployed token.
     * @param pair The address of the Uniswap V2 pair.
     */
    error LiquidityDeployer_TotalSupplyZero(address token, address pair);

    // #endregion ----------------------------------------------------------------------------------- //

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
     * @notice Emitted when liquidity is unwound from a pair.
     * @param pair The address of the Uniswap V2 pair that liquidity was unwound from.
     * @param originator The address that originated the request (i.e., the user).
     * @param amount The amount of liquidity unwound.
     */
    event UnwindLiquidity(address indexed pair, address indexed originator, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct LiquidityDeployment {
        address token;
        address originator;
        uint256 amount;
        uint256 deadline;
        bool isUnwound;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /**
     * @notice The level of asset liquidity in pair at which early unwinding is allowed.
     */
    uint256 public immutable EARLY_UNWIND_THRESHOLD;

    /// @notice The address of the fee calculator contract.
    address public immutable FEE_CALCULATOR;

    /// @notice The address of the liquidity pool contract.
    address public immutable LIQUIDITY_POOL;

    /// @notice The maximum amount that can be deployed as liquidity.
    uint256 public immutable MAX_DEPLOYMENT_AMOUNT;

    /// @notice The maximum duration for liquidity deployment.
    uint256 public immutable MAX_DURATION;

    /// @notice The minimum amount that can be deployed as liquidity.
    uint256 public immutable MIN_DEPLOYMENT_AMOUNT;

    /// @notice The minimum duration for liquidity deployment.
    uint256 public immutable MIN_DURATION;

    /// @notice The address of the reserve to which collected fees are sent.
    address public immutable RESERVE;

    /**
     * @notice The reserve factor for the LiquidityDeployer.
     * @dev Represented in 18 decimals (e.g., 1e18 = 100%).
     */
    uint256 public immutable RESERVE_FACTOR;

    /// @notice The WETH contract address.
    address public immutable WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @notice The liquidity deployer role.
    bytes32 public constant LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice A mapping of liquidity deployments.
    mapping(address pair => LiquidityDeployment) public liquidityDeployments;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * Constructor
     * @param admin_ The address to grant the admin role.
     * @param earlyUnwindThreshold_ The level of asset liquidity in pair at which early unwinding is allowed.
     * @param feeCalculator_ The address of the fee calculator contract.
     * @param liquidityPool_ The address of the liquidity pool contract.
     * @param maxDeploymentAmount_ The maximum amount that can be deployed as liquidity.
     * @param maxDuration_ The maximum duration for liquidity deployment.
     * @param minDeploymentAmount_ The minimum amount that can be deployed as liquidity.
     * @param minDuration_ The minimum duration for liquidity deployment.
     * @param reserve_ The address of the reserve to which collected fees are sent.
     * @param reserveFactor_ The reserve factor for collected fees.
     */
    constructor(
        address admin_,
        uint256 earlyUnwindThreshold_,
        address feeCalculator_,
        address liquidityPool_,
        uint256 maxDeploymentAmount_,
        uint256 maxDuration_,
        uint256 minDeploymentAmount_,
        uint256 minDuration_,
        address reserve_,
        uint256 reserveFactor_
    ) {
        EARLY_UNWIND_THRESHOLD = earlyUnwindThreshold_;
        FEE_CALCULATOR = feeCalculator_;
        LIQUIDITY_POOL = liquidityPool_;
        MAX_DEPLOYMENT_AMOUNT = maxDeploymentAmount_;
        MAX_DURATION = maxDuration_;
        MIN_DEPLOYMENT_AMOUNT = minDeploymentAmount_;
        MIN_DURATION = minDuration_;
        RESERVE = reserve_;
        RESERVE_FACTOR = reserveFactor_;
        WETH = LiquidityPool(liquidityPool_).asset();
        _grantRole({ role: DEFAULT_ADMIN_ROLE, account: admin_ });
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
     * - `msg.value` must be equal to the liquidity deployment fee.
     *
     * Actions:
     * 1. Store the liquidity deployment.
     * 2. Dispatch asset from LiquidityPool to the pair.
     *
     * @param originator The address that originated the request (i.e., the user).
     * @param pair The address of the Uniswap V2 pair that will receive liquidity.
     * @param token The address of the token that will be deployed as liquidity.
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
        payable
        onlyRole(LIQUIDITY_DEPLOYER_ROLE)
        whenNotPaused
    {
        // Checks: Pair must not have received liquidity before.
        if (liquidityDeployments[pair].deadline != 0) {
            revert LiquidityDeployer_PairAlreadyReceivedLiquidity({ token: token, pair: pair });
        }
        // Checks: Total supply of the deployed token must be greater than 0.
        uint256 totalSupply = IERC20(token).totalSupply();
        if (totalSupply == 0) {
            revert LiquidityDeployer_TotalSupplyZero({ token: token, pair: pair });
        }
        // Checks: Pair should contain entire supply of the deployed token.
        uint256 pairBalance = IERC20(token).balanceOf(address(pair));
        if (pairBalance != totalSupply) {
            revert LiquidityDeployer_PairSupplyDiscrepancy({
                token: token,
                pair: pair,
                pairBalance: pairBalance,
                totalSupply: totalSupply
            });
        }
        // Checks: Amount to deploy must not be less than minimum limit.
        if (amount < MIN_DEPLOYMENT_AMOUNT) {
            revert LiquidityDeployer_MinLiquidtyAmount(amount);
        }
        // Checks: Amount to deploy must not be greater than maximum limit.
        if (amount > MAX_DEPLOYMENT_AMOUNT) {
            revert LiquidityDeployer_MaxLiquidtyAmount(amount);
        }
        // Checks: Duration must not be less than minimum limit.
        if (duration < MIN_DURATION) {
            revert LiquidityDeployer_MinDuration(duration);
        }
        // Checks: Duration must not be greater than maximum limit.
        if (duration > MAX_DURATION) {
            revert LiquidityDeployer_MaxDuration(duration);
        }
        // Checks: `msg.value` must be at least the liquidity deployment fee.
        (uint256 fee, uint256 reserveCut) = FeeCalculator(FEE_CALCULATOR).calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: duration,
                lastAvailableLiquidity: LiquidityPool(LIQUIDITY_POOL).totalAssets(),
                lastDeployedLiquidity: LiquidityPool(LIQUIDITY_POOL).outstandingAssets(),
                newDeployedLiquidity: amount,
                reserveFactor: RESERVE_FACTOR
            })
        );
        if (msg.value < fee) {
            revert LiquidityDeployer_FeeMismatch({ expected: fee, received: msg.value });
        }

        // Effects: Store the liquidity deployment.
        uint256 deadline = block.timestamp + duration;
        liquidityDeployments[pair] = LiquidityDeployment({
            token: token,
            originator: originator,
            amount: amount,
            deadline: deadline,
            isUnwound: false
        });

        // Interactions: Swap any excess ETH to tokens.
        uint256 excessAmount = msg.value - fee;
        if (excessAmount > 0) {
            // TODO: Limit how much can be swapped.

            // Interactions: Convert excess ETH to WETH.
            IWETH(WETH).deposit{ value: excessAmount }();
            // Interactions: Transfer excess WETH to the pair.
            IWETH(WETH).transfer(pair, excessAmount);

            bool isToken0WETH = IUniswapV2Pair(pair).token0() == WETH;
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
            (uint256 wethReserve, uint256 tokenReserve) = isToken0WETH ? (reserve0, reserve1) : (reserve1, reserve0);
            uint256 amountInWithFee = excessAmount * 997;
            uint256 numerator = amountInWithFee * tokenReserve;
            uint256 denominator = (wethReserve * 1000) + amountInWithFee;
            uint256 amountOut = numerator / denominator;

            // Interactions: Swap excess WETH to tokens.
            IUniswapV2Pair(pair).swap({
                amount0Out: isToken0WETH ? amountOut : 0,
                amount1Out: isToken0WETH ? 0 : amountOut,
                to: originator,
                data: ""
            });
        }
        // Interactions: Dispatch asset from LiquidityPool to the pair.
        LiquidityPool(LIQUIDITY_POOL).dispatchAsset({ to: pair, amount: amount, data: abi.encode(reserveCut) });

        // Emit an event.
        emit DeployLiquidity({ originator: originator, token: token, pair: pair, amount: amount, deadline: deadline });
    }

    /**
     * @notice Pause the contract.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

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
    function unwindLiquidityEMERGENCY(address[] calldata pairs) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        for (uint256 i = 0; i < pairs.length; i++) {
            address pair = pairs[i];
            LiquidityDeployment storage deployment = liquidityDeployments[pair];
            // Checks: Pair must have received liquidity before.
            if (deployment.deadline == 0) {
                revert LiquidityDeployer_PairNotReceivedLiquidity({ pair: pair });
            }
            // Checks: Pair must not have been unwound before.
            if (deployment.isUnwound) {
                revert LiquidityDeployer_AlreadyUnwound({ pair: pair });
            }

            // Effects: Set deployment as unwound.
            deployment.isUnwound = true;

            // Interactions: Return asset to the LiquidityPool.
            // TODO: check if we want to update fee mechanism for this emergency unwind.
            LiquidityPool(LIQUIDITY_POOL).returnAsset({
                from: address(this),
                amount: deployment.amount,
                data: abi.encode(pair, deployment.token)
            });

            // Emit an event.
            emit UnwindLiquidity({ pair: pair, originator: deployment.originator, amount: deployment.amount });
        }
    }

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
    function unwindLiquidity(address pair) external {
        LiquidityDeployment storage deployment = liquidityDeployments[pair];
        // Checks: Pair must have received liquidity before.
        if (deployment.deadline == 0) {
            revert LiquidityDeployer_PairNotReceivedLiquidity({ pair: pair });
        }
        // Checks: Pair must not have been unwound before.
        if (deployment.isUnwound) {
            revert LiquidityDeployer_AlreadyUnwound({ pair: pair });
        }
        // Checks: Deadline must have passed or early unwind threshold must be met.
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 wethReserve, uint256 tokenReserve) =
            IUniswapV2Pair(pair).token0() == WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        if (deployment.deadline < block.timestamp && wethReserve < deployment.amount + EARLY_UNWIND_THRESHOLD) {
            revert LiquidityDeployer_UnwindNotReady({ pair: pair, deadline: deployment.deadline });
        }

        // Effects: Set deployment as unwound.
        deployment.isUnwound = true;

        // Interactions: Return asset to the LiquidityPool.
        LiquidityPool(LIQUIDITY_POOL).returnAsset({
            from: address(this),
            amount: deployment.amount,
            data: abi.encode(pair, deployment.token, wethReserve, tokenReserve)
        });

        // Emit an event.
        emit UnwindLiquidity({ pair: pair, originator: deployment.originator, amount: deployment.amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CALLBACK FUNCTIONS +|=------------------------------ //

    /**
     * @dev See {IDispatchAssetCallback-onDispatchAsset}.
     *
     * Requirements:
     * - `msg.sender` must be the LiquidityPool.
     *
     * Actions:
     * 1. Mint LP tokens.
     * 2. Convert received fee from ETH to WETH.
     * 3. Deposit the reserve cut and transfer share to the reserve.
     * 4. Transfer the remaining fee to the LiquidityPool.
     *
     * @param to The pair address to which the liquidity is deployed.
     * @param data The data passed to the callback.
     */
    function onDispatchAsset(address to, uint256, bytes calldata data) external override {
        // Checks: `msg.sender` must be the LiquidityPool.
        if (msg.sender != LIQUIDITY_POOL) {
            revert LiquidityDeployer_InvalidCallbackSender({ sender: msg.sender });
        }
        // Interactions: Mint LP tokens.
        IUniswapV2Pair(to).mint(address(this));
        // Interactions: Convert received fee from ETH to WETH.
        IWETH(WETH).deposit{ value: address(this).balance }();
        // Interactions: Deposit the reserve cut and transfer share to the reserve.
        (uint256 reserveCut) = abi.decode(data, (uint256));
        // TODO: optimize approval logic.
        // Interactions: Approve the LiquidityPool to spend reserve cut.
        IERC20(WETH).approve(LIQUIDITY_POOL, reserveCut);
        // Interactions: Deposit the reserve cut and transfer share to the reserve.
        LiquidityPool(LIQUIDITY_POOL).deposit(reserveCut, RESERVE);
        // Interactions: Transfer the remaining fee to the LiquidityPool.
        IERC20(WETH).transfer(LIQUIDITY_POOL, IERC20(WETH).balanceOf(address(this)));
    }

    /**
     * @dev See {IReturnAssetCallback-onReturnAsset}.
     *
     * Requirements:
     * - `msg.sender` must be the LiquidityPool.
     *
     * Actions:
     * 1. Calculate amount of LP tokens to redeem in order to unwind the deployed liquidity + reserve fee.
     * 2. If the LP tokens to redeem are greater than the balance, cap the amount to the balance.
     * 3. Else if the LP tokens to redeem are less than the balance, burn the excess LP tokens to avoid rug pulling
     * traders.
     * 4. Burn the LP tokens to redeem the deployed liquidity + reserve fee.
     * 5. Burn entire balance of deployed token.
     * 6. Deposit the reserve fee and transfer share to the reserve.
     *
     * @param amount The amount of WETH to return to the LiquidityPool.
     * @param data The data passed to the callback.
     */
    function onReturnAsset(address, uint256 amount, bytes calldata data) external override {
        // Checks: `msg.sender` must be the LiquidityPool.
        if (msg.sender != LIQUIDITY_POOL) {
            revert LiquidityDeployer_InvalidCallbackSender({ sender: msg.sender });
        }

        // TODO: double-check this calculation.
        (address pair, address token, uint256 wethReserve, uint256 tokenReserve) =
            abi.decode(data, (address, address, uint256, uint256));
        // TODO: use more intuitive local variable names.
        uint256 finalAmount = IERC20(WETH).balanceOf(pair);
        uint256 excessAmount = finalAmount - amount;
        // Calculate a reserve fee from the excess amount.
        uint256 reserveFee = (ud(excessAmount) * ud(RESERVE_FACTOR)).intoUint256();
        // Get the LP token balance.
        uint256 lpTokenBalance = IUniswapV2Pair(pair).balanceOf(address(this));

        // Interactions: Transfer LP token balance to the pair.
        IUniswapV2Pair(pair).transfer(pair, lpTokenBalance);
        // Interactions: Burn the LP tokens to redeem the underlying assets.
        IUniswapV2Pair(pair).burn(address(this));
        uint256 wethToReturn = wethReserve - (amount + reserveFee);
        uint256 tokenToReturn = (ud(tokenReserve) * (ud(wethToReturn) / ud(wethReserve))).intoUint256();
        // Interactions: Transfer the WETH to return to the pair.
        IERC20(WETH).transfer(pair, wethToReturn);
        // Interactions: Transfer the deployed token to return to the pair.
        IERC20(token).transfer(pair, tokenToReturn);
        // Interactions: Mint LP tokens and send them to the 0 address to lock them.
        IUniswapV2Pair(pair).mint(address(0));
        // Interactions: Burn entire remaining balance of deployed token.
        IERC20(token).transfer(address(0), IERC20(token).balanceOf(address(this)));
        // TODO: optimize approval logic.
        // Approve the LiquidityPool to spend reserve fee.
        IERC20(WETH).approve(LIQUIDITY_POOL, reserveFee);
        // Interactions: Deposit the reserve fee and transfer share to the reserve.
        LiquidityPool(LIQUIDITY_POOL).deposit(reserveFee, RESERVE);
        // Interactions: Approve the LiquidityPool to transfer the returned WETH.
        IERC20(WETH).approve(LIQUIDITY_POOL, amount);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
