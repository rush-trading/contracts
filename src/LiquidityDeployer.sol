// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IWETH } from "src/external/IWETH.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { Errors } from "src/libraries/Errors.sol";
import { FC, LD } from "src/types/DataTypes.sol";

/**
 * @title LiquidityDeployer
 * @notice See the documentation in {ILiquidityDeployer}.
 */
contract LiquidityDeployer is ILiquidityDeployer, Pausable, ACLRoles {
    using SafeCast for uint256;

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override EARLY_UNWIND_THRESHOLD;

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
    uint256 public immutable override REWARD_FACTOR;

    /// @inheritdoc ILiquidityDeployer
    address public immutable RUSH_SMART_LOCK;

    /// @inheritdoc ILiquidityDeployer
    uint256 public immutable override SURPLUS_FACTOR;

    /// @inheritdoc ILiquidityDeployer
    address public immutable override WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev A mapping of liquidity deployments.
    mapping(address uniV2Pair => LD.LiquidityDeployment) internal _liquidityDeployments;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @inheritdoc ILiquidityDeployer
    address public override feeCalculator;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param params The constructor parameters.
     */
    constructor(LD.ConstructorParam memory params) ACLRoles(params.aclManager_) {
        EARLY_UNWIND_THRESHOLD = params.earlyUnwindThreshold_;
        feeCalculator = params.feeCalculator_;
        LIQUIDITY_POOL = params.liquidityPool_;
        MAX_DEPLOYMENT_AMOUNT = params.maxDeploymentAmount_;
        MAX_DURATION = params.maxDuration_;
        MIN_DEPLOYMENT_AMOUNT = params.minDeploymentAmount_;
        MIN_DURATION = params.minDuration_;
        RESERVE = params.reserve_;
        RESERVE_FACTOR = params.reserveFactor_;
        REWARD_FACTOR = params.rewardFactor_;
        RUSH_SMART_LOCK = params.rushSmartLock_;
        SURPLUS_FACTOR = params.surplusFactor_;
        WETH = ILiquidityPool(params.liquidityPool_).asset();
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
        uint256 duration,
        uint256 maxTotalFee
    )
        external
        payable
        override
        onlyLauncherRole
        whenNotPaused
    {
        LD.DeployLiquidityLocalVars memory vars;
        // Checks: Pair must not have received liquidity before.
        if (_liquidityDeployments[uniV2Pair].deadline > 0) {
            revert Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity({ rushERC20: rushERC20, uniV2Pair: uniV2Pair });
        }
        // Checks: Total supply of the RushERC20 token must be greater than 0.
        vars.rushERC20TotalSupply = IERC20(rushERC20).totalSupply();
        if (vars.rushERC20TotalSupply == 0) {
            revert Errors.LiquidityDeployer_TotalSupplyZero({ rushERC20: rushERC20, uniV2Pair: uniV2Pair });
        }
        // Checks: Pair should hold entire supply of the RushERC20 token.
        vars.rushERC20BalanceOfPair = IERC20(rushERC20).balanceOf(uniV2Pair);
        if (vars.rushERC20BalanceOfPair != vars.rushERC20TotalSupply) {
            revert Errors.LiquidityDeployer_PairSupplyDiscrepancy({
                rushERC20: rushERC20,
                uniV2Pair: uniV2Pair,
                rushERC20BalanceOfPair: vars.rushERC20BalanceOfPair,
                rushERC20TotalSupply: vars.rushERC20TotalSupply
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
        (vars.totalFee, vars.reserveFee) = IFeeCalculator(feeCalculator).calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: amount,
                outstandingLiquidity: ILiquidityPool(LIQUIDITY_POOL).outstandingAssets(),
                reserveFactor: RESERVE_FACTOR,
                totalLiquidity: ILiquidityPool(LIQUIDITY_POOL).lastSnapshotTotalAssets()
            })
        );
        if (msg.value < vars.totalFee) {
            revert Errors.LiquidityDeployer_FeeMismatch({ expected: vars.totalFee, received: msg.value });
        }
        // Checks: Maximum total fee must not be exceeded.
        if (vars.totalFee > maxTotalFee) {
            revert Errors.LiquidityDeployer_MaxTotalFeeExceeded({ totalFee: vars.totalFee, maxTotalFee: maxTotalFee });
        }

        // Effects: Store the liquidity deployment.
        vars.deadline = block.timestamp + duration;
        _liquidityDeployments[uniV2Pair] = LD.LiquidityDeployment({
            amount: amount.toUint208(),
            deadline: vars.deadline.toUint40(),
            isUnwound: false,
            isUnwindThresholdMet: false,
            subsidyAmount: vars.reserveFee.toUint96(),
            rushERC20: rushERC20,
            originator: originator
        });

        // Interactions: Dispatch asset from LiquidityPool to the pair.
        ILiquidityPool(LIQUIDITY_POOL).dispatchAsset({ to: uniV2Pair, amount: amount });
        // Interactions: Convert received value from ETH to WETH.
        IWETH(WETH).deposit{ value: msg.value }();
        // Interactions: Transfer reserve fee portion to the pair to maintain `_unwindLiquidity` invariant.
        IERC20(WETH).transfer(uniV2Pair, vars.reserveFee);
        // Interactions: Transfer the remaining portion of the fee to the LiquidityPool as APY.
        IERC20(WETH).transfer(LIQUIDITY_POOL, vars.totalFee - vars.reserveFee);
        // Interactions: Mint LP tokens to the contract.
        IUniswapV2Pair(uniV2Pair).mint(address(this));
        // Interactions: Swap any excess ETH to RushERC20.
        unchecked {
            vars.excessValue = msg.value - vars.totalFee;
        }
        if (vars.excessValue > 0) {
            _swapWETHToRushERC20({ uniV2Pair: uniV2Pair, originator: originator, wethAmountIn: vars.excessValue });
        }

        // Emit an event.
        emit DeployLiquidity({
            originator: originator,
            rushERC20: rushERC20,
            uniV2Pair: uniV2Pair,
            amount: amount,
            totalFee: vars.totalFee,
            reserveFee: vars.reserveFee,
            deadline: vars.deadline
        });
    }

    /// @inheritdoc ILiquidityDeployer
    function pause() external override onlyAdminRole {
        _pause();

        // Emit an event.
        emit Pause();
    }

    /// @inheritdoc ILiquidityDeployer
    function setFeeCalculator(address newFeeCalculator) external override onlyAdminRole whenPaused {
        // Checks: New FeeCalculator address must not be the zero address.
        if (newFeeCalculator == address(0)) {
            revert Errors.LiquidityDeployer_FeeCalculatorZeroAddress();
        }

        // Effects: Set the new FeeCalculator address.
        feeCalculator = newFeeCalculator;

        // Emit an event.
        emit SetFeeCalculator({ newFeeCalculator: newFeeCalculator });
    }

    /// @inheritdoc ILiquidityDeployer
    function unpause() external override onlyAdminRole {
        _unpause();

        // Emit an event.
        emit Unpause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidityEMERGENCY(address[] calldata uniV2Pairs) external override onlyAdminRole whenPaused {
        for (uint256 i; i < uniV2Pairs.length; ++i) {
            // Unwind the liquidity deployment with emergency override.
            _unwindLiquidity({ uniV2Pair: uniV2Pairs[i], emergencyOverride: true });
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidity(address uniV2Pair) external override whenNotPaused {
        // Unwind the liquidity deployment.
        _unwindLiquidity({ uniV2Pair: uniV2Pair, emergencyOverride: false });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

    function _getIsUnwindThresholdMet(address uniV2Pair) internal view returns (bool isUnwindThresholdMet) {
        LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];
        (uint256 currentReserve,,) = _getOrderedReserves(uniV2Pair);
        uint256 targetReserve = deployment.amount + deployment.subsidyAmount + EARLY_UNWIND_THRESHOLD;
        isUnwindThresholdMet = currentReserve >= targetReserve;
    }

    /// @dev Returns the ordered amounts of the Uniswap V2 pair with the ordering.
    function _getOrderedAmounts(
        address uniV2Pair,
        uint256 amount0,
        uint256 amount1
    )
        internal
        view
        returns (uint256 wethAmount, uint256 rushERC20Amount, bool isToken0WETH)
    {
        isToken0WETH = IUniswapV2Pair(uniV2Pair).token0() == WETH;
        (wethAmount, rushERC20Amount) = isToken0WETH ? (amount0, amount1) : (amount1, amount0);
    }

    /// @dev Returns the ordered reserves of the Uniswap V2 pair with the ordering.
    function _getOrderedReserves(address uniV2Pair)
        internal
        view
        returns (uint256 wethReserve, uint256 rushERC20Reserve, bool isToken0WETH)
    {
        isToken0WETH = IUniswapV2Pair(uniV2Pair).token0() == WETH;
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniV2Pair).getReserves();
        (wethReserve, rushERC20Reserve) = isToken0WETH ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /**
     * @dev Swaps WETH to RushERC20 via Uniswap V2 pair.
     * @dev Swap calculation logic mimics the logic of `UniswapV2Library.getAmountOut` function.
     * Reference:
     * https://github.com/Uniswap/v2-periphery/blob/0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f/contracts/libraries/UniswapV2Library.sol#L43
     */
    function _swapWETHToRushERC20(address uniV2Pair, address originator, uint256 wethAmountIn) internal {
        // Calculate the maximum amount of RushERC20 to receive from the swap.
        (uint256 wethReserve, uint256 rushERC20Reserve, bool isToken0WETH) = _getOrderedReserves(uniV2Pair);
        uint256 wethAmountInWithFee = Math.mulDiv(wethAmountIn, 0.997e18, 1e18);
        uint256 maxAmountRushERC20Out =
            Math.mulDiv(wethAmountInWithFee, rushERC20Reserve, wethReserve + wethAmountInWithFee);

        // Interactions: Transfer WETH to the pair.
        IERC20(WETH).transfer(uniV2Pair, wethAmountIn);
        // Interactions: Swap WETH to equivalent RushERC20.
        IUniswapV2Pair(uniV2Pair).swap({
            amount0Out: isToken0WETH ? 0 : maxAmountRushERC20Out,
            amount1Out: isToken0WETH ? maxAmountRushERC20Out : 0,
            to: originator,
            data: ""
        });
    }

    /**
     * @dev Unwinds the liquidity deployment.
     * @dev The invariant here is that the exact deployed amount must always be unwindable. This can only be guaranteed
     * by configuring the protocol with sensible values in order to:
     * 1. Ensure that the reserve fee is always sufficient to subsidize the infinitesimal LP dilution in UniswapV2Pair
     * implementation, as 1e3 LP tokens are minted and forever locked when `mint` is called for the first time, meaning
     * that burning the LP tokens minted during `deployLiquidity` execution would yield slightly less balances than the
     * original supplied amounts, assuming no swaps have occurred on the pair.
     * 2. Ensure that both the WETH and RushERC20 amounts resupplied to the pair are always greater than 0 to prevent
     * `UniswapV2Pair.mint` from reverting with `INSUFFICIENT_LIQUIDITY_MINTED`.
     * Reference:
     * https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/UniswapV2Pair.sol#L110
     *
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param emergencyOverride Flag to override the deadline and early unwind threshold checks.
     */
    function _unwindLiquidity(address uniV2Pair, bool emergencyOverride) internal {
        LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];

        // Checks: Pair must have received liquidity before.
        if (deployment.deadline == 0) {
            revert Errors.LiquidityDeployer_PairNotReceivedLiquidity({ uniV2Pair: uniV2Pair });
        }
        // Checks: Pair must not have been unwound before.
        if (deployment.isUnwound) {
            revert Errors.LiquidityDeployer_PairAlreadyUnwound({ uniV2Pair: uniV2Pair });
        }

        LD.UnwindLiquidityLocalVars memory vars;
        vars.isUnwindThresholdMet = _getIsUnwindThresholdMet(uniV2Pair);

        // Checks: For non-emergency unwinding, deadline must have passed or early unwind threshold must be met.
        if (!emergencyOverride && block.timestamp < deployment.deadline && !vars.isUnwindThresholdMet) {
            revert Errors.LiquidityDeployer_UnwindNotReady({
                uniV2Pair: uniV2Pair,
                deadline: deployment.deadline,
                isUnwindThresholdMet: vars.isUnwindThresholdMet
            });
        }

        // Effects: Set deployment as unwound.
        deployment.isUnwound = true;

        // Effects: Set the unwind threshold flag.
        deployment.isUnwindThresholdMet = vars.isUnwindThresholdMet;

        // Interactions: Transfer entire LP token balance to the pair.
        IERC20(uniV2Pair).transfer(uniV2Pair, IERC20(uniV2Pair).balanceOf(address(this)));

        // Interactions: Burn the LP tokens to redeem the underlying assets.
        (vars.amount0, vars.amount1) = IUniswapV2Pair(uniV2Pair).burn({ to: address(this) });
        (vars.wethBalance, vars.rushERC20Balance,) =
            _getOrderedAmounts({ uniV2Pair: uniV2Pair, amount0: vars.amount0, amount1: vars.amount1 });

        vars.initialWETHReserve = deployment.amount + deployment.subsidyAmount;

        // If the WETH balance is greater than the initial reserve, the pair has a surplus.
        if (vars.wethBalance > vars.initialWETHReserve) {
            // Calculate the surplus.
            unchecked {
                vars.wethSurplus = vars.wethBalance - vars.initialWETHReserve;
            }
            if (vars.isUnwindThresholdMet) {
                // Tax the surplus to the reserve.
                vars.wethSurplusTax = Math.mulDiv(vars.wethSurplus, SURPLUS_FACTOR, 1e18);
                // Calculate the total reserve fee.
                unchecked {
                    vars.totalReserveFee = deployment.subsidyAmount + vars.wethSurplusTax;
                }
                // Calculate the amount of WETH to resupply to the pair.
                unchecked {
                    vars.wethToResupply = vars.wethSurplus - vars.wethSurplusTax;
                }

                // Calculate the amount of RushERC20 to resupply to the pair.
                vars.rushERC20ToResupply = Math.mulDiv(vars.rushERC20Balance, vars.wethToResupply, vars.wethBalance);

                // Calculate the amount of RushERC20 to reward to the originator.
                vars.rushERC20ToReward =
                    Math.mulDiv(vars.rushERC20Balance - vars.rushERC20ToResupply, REWARD_FACTOR, 1e18);
            } else {
                // Calculate the total reserve fee.
                unchecked {
                    vars.totalReserveFee = deployment.subsidyAmount;
                }
                // Calculate the amount of WETH to resupply to the pair.
                unchecked {
                    vars.wethToResupply = vars.wethSurplus;
                }

                // Calculate the amount of RushERC20 to resupply to the pair.
                vars.rushERC20ToResupply = Math.mulDiv(vars.rushERC20Balance, vars.wethToResupply, vars.wethBalance * 4);
            }

            // Interactions: Transfer the WETH to resupply to the pair.
            IERC20(WETH).transfer(uniV2Pair, vars.wethToResupply);
            // Interactions: Transfer the RushERC20 to resupply to the pair.
            IERC20(deployment.rushERC20).transfer(uniV2Pair, vars.rushERC20ToResupply);
            // Interactions: Mint LP tokens and send them to the RushERC20 token address to lock them forever.
            try IUniswapV2Pair(uniV2Pair).mint(deployment.rushERC20) { }
            catch {
                // If minting fails, gracefully recover by syncing the pair without minting LP tokens.
                // Interactions: Sync the pair.
                IUniswapV2Pair(uniV2Pair).sync();
            }
        }
        // Else, the pair had no swaps and the total reserve fee is whatever is left of the fee after subsidy.
        else {
            // Calculate the total reserve fee.
            vars.totalReserveFee = vars.wethBalance - deployment.amount;
        }

        if (vars.rushERC20ToReward > 0) {
            // Interactions: Transfer the RushERC20 to reward to the originator.
            IERC20(deployment.rushERC20).transfer(deployment.originator, vars.rushERC20ToReward);
        }
        // Interactions: Burn entire remaining balance of the RushERC20 token by sending it to the RushSmartLock
        // contract.
        IERC20(deployment.rushERC20).transfer(
            RUSH_SMART_LOCK, vars.rushERC20Balance - vars.rushERC20ToResupply - vars.rushERC20ToReward
        );
        // Interactions: Transfer the total reserve fee to the reserve.
        IERC20(WETH).transfer(RESERVE, vars.totalReserveFee);
        // Interactions: Approve the LiquidityPool to transfer the liquidity deployment amount.
        IERC20(WETH).approve(LIQUIDITY_POOL, deployment.amount);
        // Interactions: Return asset to the LiquidityPool.
        ILiquidityPool(LIQUIDITY_POOL).returnAsset({ from: address(this), amount: deployment.amount });

        // Emit an event.
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: deployment.originator, amount: deployment.amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
