// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseHandler } from "./BaseHandler.sol";
import { RushLauncherStore } from "../stores/RushLauncherStore.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployerWETH } from "src/LiquidityDeployerWETH.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";

/// @notice Exposes the core functionality holistically to Foundry for invariant testing purposes.
contract RushLauncherHandler is BaseHandler {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    FeeCalculator internal feeCalculator;
    RushLauncher internal rushLauncher;
    RushLauncherStore internal rushLauncherStore;
    LiquidityDeployerWETH internal liquidityDeployerWETH;
    LiquidityPool internal liquidityPool;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    address internal immutable weth;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor(RushLauncher rushLauncher_, RushLauncherStore rushLauncherStore_) {
        rushLauncher = rushLauncher_;
        rushLauncherStore = rushLauncherStore_;
        liquidityDeployerWETH = LiquidityDeployerWETH(rushLauncher_.LIQUIDITY_DEPLOYER());
        feeCalculator = FeeCalculator(liquidityDeployerWETH.FEE_CALCULATOR());
        liquidityPool = LiquidityPool(liquidityDeployerWETH.LIQUIDITY_POOL());
        weth = liquidityPool.asset();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct LaunchParams {
        string name;
        string symbol;
        uint256 maxSupply;
        bytes data;
        uint256 liquidityAmount;
        uint256 liquidityDuration;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ HANDLER FUNCTIONS +|=------------------------------- //

    function launch(LaunchParams memory params) external useNewSender(address(this)) {
        // Bound the `maxSupply` to the range (MIN_SUPPLY_LIMIT, MAX_SUPPL_LIMITY).
        params.maxSupply = bound(params.maxSupply, rushLauncher.MIN_SUPPLY_LIMIT(), rushLauncher.MAX_SUPPLY_LIMIT());
        // Bound the `liquidityAmount` to the range (MIN_DEPLOYMENT_AMOUNT, MAX_DEPLOYMENT_AMOUNT).
        params.liquidityAmount = bound(
            params.liquidityAmount,
            liquidityDeployerWETH.MIN_DEPLOYMENT_AMOUNT(),
            liquidityDeployerWETH.MAX_DEPLOYMENT_AMOUNT()
        );
        // Bound the `liquidityDuration` to the range (MIN_DURATION, MAX_DURATION).
        params.liquidityDuration =
            bound(params.liquidityDuration, liquidityDeployerWETH.MIN_DURATION(), liquidityDeployerWETH.MAX_DURATION());
        // Supply LiquidityPool with required liquidity.
        uint256 wethReserve = IERC20(weth).balanceOf(address(liquidityPool));
        if (wethReserve < liquidityDeployerWETH.MAX_DEPLOYMENT_AMOUNT()) {
            uint256 amount = liquidityDeployerWETH.MAX_DEPLOYMENT_AMOUNT() - wethReserve;
            // Give required assets.
            deal({ token: weth, to: address(this), give: amount });
            // Approve the LiquidityPool to spend the assets.
            approveFrom({ token: weth, owner: address(this), spender: address(liquidityPool), amount: amount });
            // Deposit the assets into the LiquidityPool.
            liquidityPool.deposit(amount, address(this));
        }
        // Supply the fee.
        (uint256 totalFee,) = feeCalculator.calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: params.liquidityDuration,
                newLiquidity: params.liquidityAmount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: liquidityDeployerWETH.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.totalAssets()
            })
        );
        vm.deal({ account: address(this), newBalance: totalFee });
        // Launch the ERC20 token market.
        (, address pair) = rushLauncher.launch{ value: totalFee }(
            RushLauncher.LaunchParams({
                templateDescription: "RushERC20Basic",
                name: params.name,
                symbol: params.symbol,
                maxSupply: params.maxSupply,
                data: params.data,
                liquidityAmount: params.liquidityAmount,
                liquidityDuration: params.liquidityDuration
            })
        );
        // Push the deployment to the store.
        rushLauncherStore.pushDeployment(pair);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
