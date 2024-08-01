// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IWETH } from "src/external/IWETH.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { Errors } from "src/libraries/Errors.sol";
import { FC, LD } from "src/types/DataTypes.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";

/**
 * @title LiquidityDeployer
 * @notice See the documentation in {ILiquidityDeployer}.
 */
contract LiquidityDeployer is ILiquidityDeployer, Pausable, ACLRoles {
    using SafeCast for uint256;
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

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev A mapping of liquidity deployments.
    mapping(address uniV2Pair => LD.LiquidityDeployment) internal _liquidityDeployments;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager_ The address of the ACLManager contract.
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
        address aclManager_,
        uint256 earlyUnwindThreshold_,
        address feeCalculator_,
        address liquidityPool_,
        uint256 maxDeploymentAmount_,
        uint256 maxDuration_,
        uint256 minDeploymentAmount_,
        uint256 minDuration_,
        address reserve_,
        uint256 reserveFactor_
    )
        ACLRoles(aclManager_)
    {
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
        onlyLauncherRole
        whenNotPaused
    {
        LD.DeployLiquidityLocalVars memory vars;
        // Checks: Pair must not have received liquidity before.
        if (_liquidityDeployments[uniV2Pair].deadline != 0) {
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
            amount: amount.toUint208(),
            deadline: vars.deadline.toUint40(),
            isUnwound: false,
            subsidyAmount: vars.reserveFee.toUint96(),
            rushERC20: rushERC20,
            originator: originator
        });

        // Interactions: Dispatch asset from LiquidityPool to the pair.
        ILiquidityPool(LIQUIDITY_POOL).dispatchAsset({ to: uniV2Pair, amount: amount });
        // Interactions: Convert received fee from ETH to WETH.
        IWETH(WETH).deposit{ value: vars.totalFee }();
        // Interactions: Transfer reserve fee portion to the pair to maintain `_unwindLiquidity` invariant.
        IERC20(WETH).safeTransfer(uniV2Pair, vars.reserveFee);
        // Interactions: Transfer the remaining portion of the fee to the LiquidityPool as APY.
        IERC20(WETH).safeTransfer(LIQUIDITY_POOL, vars.totalFee - vars.reserveFee);
        // Interactions: Mint LP tokens to the contract.
        IUniswapV2Pair(uniV2Pair).mint(address(this));
        // Interactions: Swap any excess ETH to RushERC20.
        vars.excessValue = msg.value - vars.totalFee;
        if (vars.excessValue > 0) {
            _swapETHToRushERC20({ uniV2Pair: uniV2Pair, originator: originator, ethAmountIn: vars.excessValue });
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
    function pause() external override onlyAdminRole {
        _pause();

        // Emit an event.
        emit Pause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unpause() external override onlyAdminRole {
        _unpause();

        // Emit an event.
        emit Unpause();
    }

    /// @inheritdoc ILiquidityDeployer
    function unwindLiquidityEMERGENCY(address[] calldata uniV2Pairs) external override onlyAdminRole whenPaused {
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

            // Unwind the liquidity deployment.
            _unwindLiquidity({ uniV2Pair: uniV2Pair });
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
        (uint256 wethReserve,,) = _getOrderedReserves(uniV2Pair);
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
        _unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

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

    /// @dev Swaps ETH to RushERC20 via Uniswap V2 pair.
    function _swapETHToRushERC20(address uniV2Pair, address originator, uint256 ethAmountIn) internal {
        // Calculate the amount of RushERC20 to receive.
        (uint256 wethReserve, uint256 rushERC20Reserve, bool isToken0WETH) = _getOrderedReserves(uniV2Pair);
        uint256 ethAmountInWithFee = ethAmountIn * 997;
        uint256 numerator = ethAmountInWithFee * rushERC20Reserve;
        uint256 denominator = (wethReserve * 1000) + ethAmountInWithFee;
        uint256 maxAmountRushERC20Out = numerator / denominator;

        // Interactions: Convert ETH to WETH.
        IWETH(WETH).deposit{ value: ethAmountIn }();
        // Interactions: Transfer WETH to the pair.
        IERC20(WETH).safeTransfer(uniV2Pair, ethAmountIn);
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
     *
     * Invariant:
     * - The full deployment amount must always be unwindable (i.e., never stuck in the pair due to rounding errors), as
     * long as the protocol is configured with default parameters.
     */
    function _unwindLiquidity(address uniV2Pair) internal {
        LD.LiquidityDeployment storage deployment = _liquidityDeployments[uniV2Pair];

        // Effects: Set deployment as unwound.
        deployment.isUnwound = true;

        // Interactions: Transfer entire LP token balance to the pair.
        IERC20(uniV2Pair).safeTransfer(uniV2Pair, IERC20(uniV2Pair).balanceOf(address(this)));
        // Interactions: Burn the LP tokens to redeem the underlying assets.
        IUniswapV2Pair(uniV2Pair).burn({ to: address(this) });

        // LP token total supply should be 1000 at this point, as those were forever locked in address(0).
        // https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/UniswapV2Pair.sol#L121

        LD.UnwindLiquidityLocalVars memory vars;
        vars.wethBalance = IERC20(WETH).balanceOf(address(this));
        vars.rushERC20Balance = IERC20(deployment.rushERC20).balanceOf(address(this));
        vars.initialWETHReserve = deployment.amount + deployment.subsidyAmount;
        if (vars.wethBalance > vars.initialWETHReserve) {
            // Calculate the total reserve fee.
            vars.wethSurplus = vars.wethBalance - vars.initialWETHReserve;
            vars.wethSurplusTax = (ud(vars.wethSurplus) * ud(RESERVE_FACTOR)).intoUint256();
            vars.totalReserveFee = deployment.subsidyAmount + vars.wethSurplusTax;
            // Calculate the amount of WETH and RushERC20 to lock in the pair.
            vars.wethToLock = vars.wethSurplus - vars.wethSurplusTax;
            vars.rushERC20ToLock =
                (ud(vars.rushERC20Balance) * (ud(vars.wethToLock) / ud(vars.wethBalance))).intoUint256();
            // Interactions: Transfer the WETH to lock to the pair.
            IERC20(WETH).safeTransfer(uniV2Pair, vars.wethToLock);
            // Interactions: Transfer the RushERC20 to lock to the pair.
            IERC20(deployment.rushERC20).safeTransfer(uniV2Pair, vars.rushERC20ToLock);
            // Interactions: Mint LP tokens send them to a burn address to lock them.
            // Calling `IUniswapV2Pair.mint` here could potentially revert if resulting liquidity is 0, which makes this
            // function susceptible to griefing attacks if error was not handled.
            try IUniswapV2Pair(uniV2Pair).mint(address(1)) { }
            catch {
                // If minting fails, gracefully recover by syncing the pair without minting LP tokens.
                IUniswapV2Pair(uniV2Pair).sync();
            }
        } else {
            // Calculate the total reserve fee.
            vars.totalReserveFee = vars.wethBalance - deployment.amount;
        }

        // Interactions: Burn entire remaining balance of the RushERC20 token.
        IERC20(deployment.rushERC20).safeTransfer(address(1), vars.rushERC20Balance - vars.rushERC20ToLock);
        // Interactions: Transfer the total reserve fee to the reserve.
        IERC20(WETH).safeTransfer(RESERVE, vars.totalReserveFee);
        // Interactions: Approve the LiquidityPool to transfer the original liquidity deployment amount.
        IERC20(WETH).approve(LIQUIDITY_POOL, deployment.amount);
        // Interactions: Return asset to the LiquidityPool.
        ILiquidityPool(LIQUIDITY_POOL).returnAsset({ from: address(this), amount: deployment.amount });

        // Emit an event.
        emit UnwindLiquidity({ uniV2Pair: uniV2Pair, originator: deployment.originator, amount: deployment.amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
