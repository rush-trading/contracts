// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IWETH } from "src/external/IWETH.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { Errors } from "src/libraries/Errors.sol";
import { FC, LD } from "src/types/DataTypes.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";

/**
 * @title LiquidityDeployer
 * @notice See the documentation in {ILiquidityDeployer}.
 */
contract LiquidityDeployer is ILiquidityDeployer, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override EARLY_UNWIND_THRESHOLD;

    /// @inheritdoc ILiquidityDeployer
    address public immutable override FEE_CALCULATOR;

    /// @inheritdoc ILiquidityDeployer
    address public immutable override LIQUIDITY_POOL;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override MAX_DEPLOYMENT_AMOUNT;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override MAX_DURATION;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override MIN_DEPLOYMENT_AMOUNT;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override MIN_DURATION;

    /// @inheritdoc ILiquidityDeployer
    address public immutable override RESERVE;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override RESERVE_FACTOR;

    /// @inheritdoc ILiquidityDeployer
    address public immutable override WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @inheritdoc ILiquidityDeployer
    bytes32 public constant override LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev A mapping of liquidity deployments.
    mapping(address uniV2Pair => LD.LiquidityDeployment) internal _liquidityDeployments;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param admin_ The address to grant the admin role.
     * @param earlyUnwindThreshold_ The level of asset liquidity in pair at which early unwinding is allowed.
     * @param feeCalculator_ The address of the FeeCalculator contract.
     * @param liquidityPool_ The address of the LiquidityPool contract.
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
        WETH = ILiquidityPool(liquidityPool_).asset();
        _grantRole({ role: DEFAULT_ADMIN_ROLE, account: admin_ });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc ILiquidityDeployer
    function getLiquidityDeployment(address uniV2Pair) external view override returns (LD.LiquidityDeployment memory) {
        return _liquidityDeployments[uniV2Pair];
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc ILiquidityDeployer
    function deployLiquidity(
        address originator,
        address uniV2Pair,
        address rushERC20,
        uint256 amount,
        uint256 duration
    )
        external
        payable
        override
        onlyRole(LIQUIDITY_DEPLOYER_ROLE)
        whenNotPaused
    {
        LD.DeployLiquidityLocalVars memory vars;
        // Checks: Pair must not have received liquidity before.
        if (_liquidityDeployments[uniV2Pair].deadline != 0) {
            revert Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity({ rushERC20: rushERC20, uniV2Pair: uniV2Pair });
        }
        // Checks: Total supply of the RushERC20 token must be greater than 0.
        vars.totalSupply = IERC20(rushERC20).totalSupply();
        if (vars.totalSupply == 0) {
            revert Errors.LiquidityDeployer_TotalSupplyZero({ rushERC20: rushERC20, uniV2Pair: uniV2Pair });
        }
        // Checks: Pair should contain entire supply of the RushERC20 token.
        vars.rushERC20BalanceOfPair = IERC20(rushERC20).balanceOf(uniV2Pair);
        if (vars.rushERC20BalanceOfPair != vars.totalSupply) {
            revert Errors.LiquidityDeployer_PairSupplyDiscrepancy({
                rushERC20: rushERC20,
                uniV2Pair: uniV2Pair,
                rushERC20BalanceOfPair: vars.rushERC20BalanceOfPair,
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
        (vars.totalFee, vars.reserveFee) = IFeeCalculator(FEE_CALCULATOR).calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: amount,
                outstandingLiquidity: ILiquidityPool(LIQUIDITY_POOL).outstandingAssets(),
                reserveFactor: RESERVE_FACTOR,
                totalLiquidity: ILiquidityPool(LIQUIDITY_POOL).totalAssets()
            })
        );
        if (msg.value < vars.totalFee) {
            revert Errors.LiquidityDeployer_FeeMismatch({ expected: vars.totalFee, received: msg.value });
        }

        // Effects: Store the liquidity deployment.
        vars.deadline = block.timestamp + duration;
        _liquidityDeployments[uniV2Pair] = LD.LiquidityDeployment({
            rushERC20: rushERC20,
            originator: originator,
            amount: amount,
            deadline: vars.deadline,
            isUnwound: false
        });

        // Interactions: Dispatch asset from LiquidityPool to the pair.
        ILiquidityPool(LIQUIDITY_POOL).dispatchAsset({
            to: uniV2Pair,
            amount: amount,
            data: abi.encode(vars.totalFee, vars.reserveFee, uniV2Pair)
        });

        // Interactions: Swap any excess ETH to tokens.
        vars.excessValue = msg.value - vars.totalFee;
        if (vars.excessValue > 0) {
            // Interactions: Convert excess ETH to WETH.
            IWETH(WETH).deposit{ value: vars.excessValue }();
            // Interactions: Transfer excess WETH to the pair.
            IERC20(WETH).safeTransfer(uniV2Pair, vars.excessValue);

            vars.isToken0WETH = IUniswapV2Pair(uniV2Pair).token0() == WETH;
            (vars.reserve0, vars.reserve1,) = IUniswapV2Pair(uniV2Pair).getReserves();
            (vars.wethReserve, vars.rushERC20Reserve) =
                vars.isToken0WETH ? (vars.reserve0, vars.reserve1) : (vars.reserve1, vars.reserve0);
            vars.amountWETHInWithFee = vars.excessValue * 997;
            vars.numerator = vars.amountWETHInWithFee * vars.rushERC20Reserve;
            vars.denominator = (vars.wethReserve * 1000) + vars.amountWETHInWithFee;
            vars.amountRushERC20Out = vars.numerator / vars.denominator;

            // Interactions: Swap excess WETH to tokens.
            IUniswapV2Pair(uniV2Pair).swap({
                amount0Out: vars.isToken0WETH ? 0 : vars.amountRushERC20Out,
                amount1Out: vars.isToken0WETH ? vars.amountRushERC20Out : 0,
                to: originator,
                data: ""
            });
        }

        // Emit an event.
        emit DeployLiquidity({
            originator: originator,
            rushERC20: rushERC20,
            uniV2Pair: uniV2Pair,
            amount: amount,
            deadline: vars.deadline
        });
    }

    /// @inheritdoc ILiquidityDeployer
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();

        // Emit an event.
        emit Pause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();

        // Emit an event.
        emit Unpause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidityEMERGENCY(address[] calldata uniV2Pairs)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenPaused
    {
        for (uint256 i = 0; i < uniV2Pairs.length; i++) {
            address uniV2Pair = uniV2Pairs[i];
            LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];
            // Checks: Pair must have received liquidity before.
            if (deployment.deadline == 0) {
                revert Errors.LiquidityDeployer_PairNotReceivedLiquidity({ uniV2Pair: uniV2Pair });
            }
            // Checks: Pair must not have been unwound before.
            if (deployment.isUnwound) {
                revert Errors.LiquidityDeployer_PairAlreadyUnwound({ uniV2Pair: uniV2Pair });
            }

            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pair).getReserves();
            (uint256 wethReserve, uint256 rushERC20Reserve) =
                IUniswapV2Pair(uniV2Pair).token0() == WETH ? (reserve0, reserve1) : (reserve1, reserve0);

            // Unwind the liquidity deployment.
            _unwindLiquidity({ uniV2Pair: uniV2Pair, wethReserve: wethReserve, rushERC20Reserve: rushERC20Reserve });
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidity(address uniV2Pair) external override {
        LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];
        // Checks: Pair must have received liquidity before.
        if (deployment.deadline == 0) {
            revert Errors.LiquidityDeployer_PairNotReceivedLiquidity({ uniV2Pair: uniV2Pair });
        }
        // Checks: Pair must not have been unwound before.
        if (deployment.isUnwound) {
            revert Errors.LiquidityDeployer_PairAlreadyUnwound({ uniV2Pair: uniV2Pair });
        }
        // Checks: Deadline must have passed or early unwind threshold must be met.
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pair).getReserves();
        (uint256 wethReserve, uint256 rushERC20Reserve) =
            IUniswapV2Pair(uniV2Pair).token0() == WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 targetWETHReserve = deployment.amount + EARLY_UNWIND_THRESHOLD;
        if (block.timestamp < deployment.deadline && wethReserve < targetWETHReserve) {
            revert Errors.LiquidityDeployer_UnwindNotReady({
                uniV2Pair: uniV2Pair,
                deadline: deployment.deadline,
                currentReserve: wethReserve,
                targetReserve: targetWETHReserve
            });
        }

        // Unwind the liquidity deployment.
        _unwindLiquidity({ uniV2Pair: uniV2Pair, wethReserve: wethReserve, rushERC20Reserve: rushERC20Reserve });
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
     * 1. Convert received fee from ETH to WETH.
     * 2. Transfer reserve fee portion to the pair to maintain `unwindLiquidity` invariant.
     * 3. Transfer the remaining portion of the fee to the LiquidityPool as APY.
     * 4. Mint LP tokens.
     *
     * @param to The pair address to which the asset is dispatched.
     * @param data The data passed to the callback.
     */
    function onDispatchAsset(address to, uint256, bytes calldata data) external override {
        // Checks: `msg.sender` must be the LiquidityPool.
        if (msg.sender != LIQUIDITY_POOL) {
            revert Errors.LiquidityDeployer_InvalidCallbackSender({ sender: msg.sender });
        }

        (uint256 totalFee, uint256 reserveFee, address uniV2Pair) = abi.decode(data, (uint256, uint256, address));
        // Interactions: Convert received fee from ETH to WETH.
        IWETH(WETH).deposit{ value: totalFee }();
        // Interactions: Transfer reserve fee portion to the pair to maintain `unwindLiquidity` invariant.
        IERC20(WETH).safeTransfer(uniV2Pair, reserveFee);
        // Interactions: Transfer the remaining portion of the fee to the LiquidityPool as APY.
        IERC20(WETH).safeTransfer(LIQUIDITY_POOL, totalFee - reserveFee);
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
     * 5. Burn entire balance of RushERC20 token.
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
        (address uniV2Pair, address rushERC20, uint256 wethReserve, uint256 rushERC20Reserve) =
            abi.decode(data, (address, address, uint256, uint256));
        // TODO: include `reserveFee` of `deployLiquidity` in the calculation.
        uint256 excessWETHAmount = wethReserve - amount;
        // Calculate a reserve fee from the excess amount.
        uint256 reserveFee = (ud(excessWETHAmount) * ud(RESERVE_FACTOR)).intoUint256();
        // Get the LP token balance.
        uint256 lpBalance = IUniswapV2Pair(uniV2Pair).balanceOf(address(this));

        // Interactions: Transfer LP token balance to the pair.
        IERC20(uniV2Pair).safeTransfer(uniV2Pair, lpBalance);
        // Interactions: Burn the LP tokens to redeem the underlying assets.
        IUniswapV2Pair(uniV2Pair).burn(address(this));
        uint256 wethToReturn = wethReserve - (amount + reserveFee);
        uint256 rushERC20ToReturn = (ud(rushERC20Reserve) * (ud(wethToReturn) / ud(wethReserve))).intoUint256();
        // Interactions: Transfer the WETH to return to the pair.
        IERC20(WETH).safeTransfer(uniV2Pair, wethToReturn);
        // Interactions: Transfer the RushERC20 to return to the pair.
        IERC20(rushERC20).safeTransfer(uniV2Pair, rushERC20ToReturn);
        // Interactions: Mint LP tokens and send them to the 1 address to lock them.
        IUniswapV2Pair(uniV2Pair).mint(address(1));
        // Interactions: Burn entire remaining balance of the RushERC20 token.
        IERC20(rushERC20).safeTransfer(address(1), IERC20(rushERC20).balanceOf(address(this)));
        // Interactions: Transfer the reserve fee to the reserve.
        IERC20(WETH).safeTransfer(RESERVE, IERC20(WETH).balanceOf(address(this)) - amount);
        // Interactions: Approve the LiquidityPool to transfer the returned WETH.
        IERC20(WETH).approve(LIQUIDITY_POOL, amount);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Unwinds the liquidity deployment.
    function _unwindLiquidity(address uniV2Pair, uint256 wethReserve, uint256 rushERC20Reserve) internal {
        LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];

        // Effects: Set deployment as unwound.
        deployment.isUnwound = true;

        // Interactions: Return asset to the LiquidityPool.
        ILiquidityPool(LIQUIDITY_POOL).returnAsset({
            from: address(this),
            amount: deployment.amount,
            data: abi.encode(uniV2Pair, deployment.rushERC20, wethReserve, rushERC20Reserve)
        });

        // Emit an event.
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: deployment.originator, amount: deployment.amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
