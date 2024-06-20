// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IWETH } from "src/external/IWETH.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { Errors } from "src/libraries/Errors.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";

/**
 * @title LiquidityDeployerWETH
 * @notice A permissioned contract for deploying WETH-backed liquidity to Uniswap V2 pairs.
 */
contract LiquidityDeployerWETH is ILiquidityDeployer, AccessControl, Pausable {
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

    /// @inheritdoc ILiquidityDeployer
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
        DeployLiquidityLocalVars memory vars;
        // Checks: Pair must not have received liquidity before.
        if (liquidityDeployments[pair].deadline != 0) {
            revert Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity({ token: token, pair: pair });
        }
        // Checks: Total supply of the deployed token must be greater than 0.
        vars.totalSupply = IERC20(token).totalSupply();
        if (vars.totalSupply == 0) {
            revert Errors.LiquidityDeployer_TotalSupplyZero({ token: token, pair: pair });
        }
        // Checks: Pair should contain entire supply of the deployed token.
        vars.pairBalance = IERC20(token).balanceOf(address(pair));
        if (vars.pairBalance != vars.totalSupply) {
            revert Errors.LiquidityDeployer_PairSupplyDiscrepancy({
                token: token,
                pair: pair,
                pairBalance: vars.pairBalance,
                totalSupply: vars.totalSupply
            });
        }
        // Checks: Amount to deploy must not be less than minimum limit.
        if (amount < MIN_DEPLOYMENT_AMOUNT) {
            revert Errors.LiquidityDeployer_MinLiquidtyAmount(amount);
        }
        // Checks: Amount to deploy must not be greater than maximum limit.
        if (amount > MAX_DEPLOYMENT_AMOUNT) {
            revert Errors.LiquidityDeployer_MaxLiquidtyAmount(amount);
        }
        // Checks: Duration must not be less than minimum limit.
        if (duration < MIN_DURATION) {
            revert Errors.LiquidityDeployer_MinDuration(duration);
        }
        // Checks: Duration must not be greater than maximum limit.
        if (duration > MAX_DURATION) {
            revert Errors.LiquidityDeployer_MaxDuration(duration);
        }
        // Checks: `msg.value` must be at least the liquidity deployment fee.
        (vars.totalFee, vars.reserveFee) = FeeCalculator(FEE_CALCULATOR).calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: duration,
                newLiquidity: amount,
                outstandingLiquidity: LiquidityPool(LIQUIDITY_POOL).outstandingAssets(),
                reserveFactor: RESERVE_FACTOR,
                totalLiquidity: LiquidityPool(LIQUIDITY_POOL).totalAssets()
            })
        );
        if (msg.value < vars.totalFee) {
            revert Errors.LiquidityDeployer_FeeMismatch({ expected: vars.totalFee, received: msg.value });
        }

        // Effects: Store the liquidity deployment.
        vars.deadline = block.timestamp + duration;
        liquidityDeployments[pair] = LiquidityDeployment({
            token: token,
            originator: originator,
            amount: amount,
            deadline: vars.deadline,
            isUnwound: false
        });

        // Interactions: Dispatch asset from LiquidityPool to the pair.
        LiquidityPool(LIQUIDITY_POOL).dispatchAsset({
            to: pair,
            amount: amount,
            data: abi.encode(vars.totalFee, vars.reserveFee, pair)
        });

        // Interactions: Swap any excess ETH to tokens.
        vars.excessAmount = msg.value - vars.totalFee;
        if (vars.excessAmount > 0) {
            // TODO: Limit how much can be swapped.

            // Interactions: Convert excess ETH to WETH.
            IWETH(WETH).deposit{ value: vars.excessAmount }();
            // Interactions: Transfer excess WETH to the pair.
            IWETH(WETH).transfer(pair, vars.excessAmount);

            vars.isToken0WETH = IUniswapV2Pair(pair).token0() == WETH;
            (vars.reserve0, vars.reserve1,) = IUniswapV2Pair(pair).getReserves();
            (vars.wethReserve, vars.tokenReserve) =
                vars.isToken0WETH ? (vars.reserve0, vars.reserve1) : (vars.reserve1, vars.reserve0);
            vars.amountInWithFee = vars.excessAmount * 997;
            vars.numerator = vars.amountInWithFee * vars.tokenReserve;
            vars.denominator = (vars.wethReserve * 1000) + vars.amountInWithFee;
            vars.amountOut = vars.numerator / vars.denominator;

            // Interactions: Swap excess WETH to tokens.
            IUniswapV2Pair(pair).swap({
                amount0Out: vars.isToken0WETH ? 0 : vars.amountOut,
                amount1Out: vars.isToken0WETH ? vars.amountOut : 0,
                to: originator,
                data: ""
            });
        }

        // Emit an event.
        emit DeployLiquidity({
            originator: originator,
            token: token,
            pair: pair,
            amount: amount,
            deadline: vars.deadline
        });
    }

    /// @inheritdoc ILiquidityDeployer
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidityEMERGENCY(address[] calldata pairs) external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        for (uint256 i = 0; i < pairs.length; i++) {
            address pair = pairs[i];
            LiquidityDeployment storage deployment = liquidityDeployments[pair];
            // Checks: Pair must have received liquidity before.
            if (deployment.deadline == 0) {
                revert Errors.LiquidityDeployer_PairNotReceivedLiquidity({ pair: pair });
            }
            // Checks: Pair must not have been unwound before.
            if (deployment.isUnwound) {
                revert Errors.LiquidityDeployer_PairAlreadyUnwound({ pair: pair });
            }

            // Effects: Set deployment as unwound.
            deployment.isUnwound = true;

            // Interactions: Return asset to the LiquidityPool.
            // TODO: check if we want to update fee mechanism for this emergency unwind.
            LiquidityPool(LIQUIDITY_POOL).returnAsset({
                from: address(this),
                amount: deployment.amount,
                // TODO: fix this data.
                data: abi.encode(pair, deployment.token)
            });

            // Emit an event.
            emit UnwindLiquidity({ pair: pair, originator: deployment.originator, amount: deployment.amount });
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidity(address pair) external {
        LiquidityDeployment storage deployment = liquidityDeployments[pair];
        // Checks: Pair must have received liquidity before.
        if (deployment.deadline == 0) {
            revert Errors.LiquidityDeployer_PairNotReceivedLiquidity({ pair: pair });
        }
        // Checks: Pair must not have been unwound before.
        if (deployment.isUnwound) {
            revert Errors.LiquidityDeployer_PairAlreadyUnwound({ pair: pair });
        }
        // Checks: Deadline must have passed or early unwind threshold must be met.
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 wethReserve, uint256 tokenReserve) =
            IUniswapV2Pair(pair).token0() == WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        if (block.timestamp < deployment.deadline && wethReserve < deployment.amount + EARLY_UNWIND_THRESHOLD) {
            // TODO: potentially include target amount to unwind in the error message.
            revert Errors.LiquidityDeployer_UnwindNotReady({ pair: pair, deadline: deployment.deadline });
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
     * 3. Deposit the reserve fee and transfer share to the reserve.
     * 4. Transfer the remaining fee to the LiquidityPool.
     *
     * @param to The pair address to which the liquidity is deployed.
     * @param data The data passed to the callback.
     */
    function onDispatchAsset(address to, uint256, bytes calldata data) external override {
        // Checks: `msg.sender` must be the LiquidityPool.
        if (msg.sender != LIQUIDITY_POOL) {
            revert Errors.LiquidityDeployer_InvalidCallbackSender({ sender: msg.sender });
        }

        (uint256 totalFee, uint256 reserveFee, address pair) = abi.decode(data, (uint256, uint256, address));
        // Interactions: Convert received fee from ETH to WETH.
        IWETH(WETH).deposit{ value: totalFee }();
        // Interactions: Transfer reserve fee to the pair to maintain `unwindLiquidity` invariant.
        IERC20(WETH).transfer(pair, reserveFee);
        // Interactions: Transfer the remaining fee to the LiquidityPool.
        IERC20(WETH).transfer(LIQUIDITY_POOL, totalFee - reserveFee);
        // Interactions: Mint LP tokens.
        IUniswapV2Pair(to).mint(address(this));
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
            revert Errors.LiquidityDeployer_InvalidCallbackSender({ sender: msg.sender });
        }

        // TODO: double-check this calculation.
        (address pair, address token, uint256 wethReserve, uint256 tokenReserve) =
            abi.decode(data, (address, address, uint256, uint256));
        // TODO: use more intuitive local variable names.
        uint256 finalAmount = IERC20(WETH).balanceOf(pair);
        // TODO: include `reserveFee` of `deployLiquidity` in the calculation.
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
        // Interactions: Mint LP tokens and send them to the 1 address to lock them.
        IUniswapV2Pair(pair).mint(address(1));
        // Interactions: Burn entire remaining balance of deployed token.
        IERC20(token).transfer(address(1), IERC20(token).balanceOf(address(this)));
        // Interactions: Transfer the reserve fee to the reserve.
        IERC20(WETH).transfer(RESERVE, IERC20(WETH).balanceOf(address(this)) - amount);
        // Interactions: Approve the LiquidityPool to transfer the returned WETH.
        IERC20(WETH).approve(LIQUIDITY_POOL, amount);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
