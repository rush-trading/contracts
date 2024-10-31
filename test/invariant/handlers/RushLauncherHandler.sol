// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { FC, RL } from "src/types/DataTypes.sol";
import { RushLauncherStore } from "./../stores/RushLauncherStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Exposes {RushLauncher} functions to Foundry for invariant testing purposes.
contract RushLauncherHandler is BaseHandler {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    IFeeCalculator internal feeCalculator;
    RushLauncher internal rushLauncher;
    RushLauncherStore internal rushLauncherStore;
    ILiquidityDeployer internal liquidityDeployer;
    ILiquidityPool internal liquidityPool;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    address internal weth;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor(RushLauncher rushLauncher_, RushLauncherStore rushLauncherStore_) {
        rushLauncher = rushLauncher_;
        rushLauncherStore = rushLauncherStore_;
        liquidityDeployer = ILiquidityDeployer(rushLauncher_.LIQUIDITY_DEPLOYER());
        feeCalculator = IFeeCalculator(liquidityDeployer.feeCalculator());
        liquidityPool = ILiquidityPool(liquidityDeployer.LIQUIDITY_POOL());
        weth = liquidityPool.asset();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct LaunchParams {
        address originator;
        string name;
        string symbol;
        uint256 maxSupply;
        uint256 liquidityAmount;
        uint256 liquidityDuration;
        bool hasExcessFee;
        uint256 excessFeeAmount;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ HANDLER FUNCTIONS +|=------------------------------- //

    function launchERC20Basic(LaunchParams memory params) external useNewSender(address(this)) {
        // Launch a RushERC20Basic token.
        _launchERC20({ params: params, kind: RUSH_ERC20_BASIC_KIND, initData: "" });
    }

    function launchERC20Taxable(
        LaunchParams memory params,
        uint256 initialTaxBasisPoints
    )
        external
        useNewSender(address(this))
    {
        // Bound the `initialTaxBasisPoints` to the range (0, 10_000).
        initialTaxBasisPoints = bound(initialTaxBasisPoints, 0, 10_000);
        // Launch a RushERC20Taxable token.
        _launchERC20({
            params: params,
            kind: RUSH_ERC20_TAXABLE_KIND,
            initData: abi.encode(params.originator, address(liquidityDeployer), uint96(initialTaxBasisPoints))
        });
    }

    function addLiquidityToPair(address pair, uint256 rushERC20Amount) external {
        // Skip when the deployment does not exist.
        if (!rushLauncherStore.deploymentExists(pair)) {
            return;
        }
        // Get the RushERC20 token address and its balance in this contract.
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        bool isToken0WETH = token0 == weth;
        address rushERC20 = isToken0WETH ? token1 : token0;
        uint256 rushERC20Balance = IERC20(rushERC20).balanceOf(address(this));
        // When `rushERC20Amount` is zero, swap the WETH for RushERC20.
        if (rushERC20Balance == 0) {
            // Give the required WETH to this contract.
            deal({ token: weth, to: address(this), give: 1 ether });
            _swapWETHForRushERC20(pair, 1 ether);
            rushERC20Balance = IERC20(rushERC20).balanceOf(address(this));
        }
        // Bound the `rushERC20Amount` to the range (0, rushERC20Balance).
        rushERC20Amount = bound(rushERC20Amount, 0, rushERC20Balance);
        // Skip when `rushERC20Amount` is zero.
        if (rushERC20Amount == 0) {
            return;
        }
        // Calculate the amount of WETH required to add liquidity.
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 wethReserve, uint256 rushERC20Reserve) = isToken0WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 wethAmount = (rushERC20Amount * wethReserve) / rushERC20Reserve;
        // Skip when the amount of WETH is zero.
        if (wethAmount == 0) {
            return;
        }
        // Give the required WETH to this contract.
        deal({ token: weth, to: address(this), give: wethAmount });
        // Transfer the WETH to the pair.
        IERC20(weth).transfer(pair, wethAmount);
        // Transfer the RushERC20 to the pair.
        IERC20(rushERC20).transfer(pair, rushERC20Amount);
        // Add liquidity to the pair.
        IUniswapV2Pair(pair).mint(address(this));
    }

    function sendWETHDirectlyToLiquidityDeployer(uint256 amount) external {
        // Bound the `amount` to the range (1 wei, 10k WETH).
        amount = bound(amount, 1 wei, 10_000 ether);
        // Give required assets to this contract.
        deal({ token: weth, to: address(this), give: amount });
        // Transfer the assets to the LiquidityDeployer.
        IERC20(weth).transfer(address(liquidityDeployer), amount);
    }

    function sendWETHDirectlyToPair(address pair, uint256 amount) external {
        // Skip when the deployment does not exist.
        if (!rushLauncherStore.deploymentExists(pair)) {
            return;
        }
        // Bound the `amount` to the range (1 wei, 10k WETH).
        amount = bound(amount, 1 wei, 10_000 ether);
        // Give required assets to this contract.
        deal({ token: weth, to: address(this), give: amount });
        // Transfer the assets to the pair.
        IERC20(weth).transfer(pair, amount);
    }

    function swapRushERC20ForWETHInPair(address pair, uint256 amount) external {
        // Skip when the deployment does not exist.
        if (!rushLauncherStore.deploymentExists(pair)) {
            return;
        }
        // Get the RushERC20 token address and its balance in this contract.
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        bool isToken0WETH = token0 == weth;
        address rushERC20 = isToken0WETH ? token1 : token0;
        uint256 rushERC20Balance = IERC20(rushERC20).balanceOf(address(this));
        // Bound the `amount` to the range (0, rushERC20Balance).
        amount = bound(amount, 0, rushERC20Balance);
        // Skip when the amount is zero.
        if (amount == 0) {
            return;
        }
        // Transfer the assets to the pair.
        IERC20(rushERC20).transfer(pair, amount);
        // Get the reserves of the pair.
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 wethReserve, uint256 rushERC20Reserve) = isToken0WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        // Get actual amount received (support fee-on-transfer tokens).
        uint256 actualAmount = IERC20(rushERC20).balanceOf(pair) - rushERC20Reserve;
        // Calculate the expected amount of WETH to receive.
        uint256 amountInWithFee = actualAmount * 997;
        uint256 numerator = amountInWithFee * wethReserve;
        uint256 denominator = rushERC20Reserve * 1000 + amountInWithFee;
        uint256 maxWETHAmount = numerator / denominator;
        // Skip when the expected amount is zero.
        if (maxWETHAmount == 0) {
            return;
        }
        // Swap the WETH for RushERC20.
        IUniswapV2Pair(pair).swap(
            isToken0WETH ? maxWETHAmount : 0, isToken0WETH ? 0 : maxWETHAmount, address(1), new bytes(0)
        );
    }

    function swapWETHForRushERC20InPair(address pair, uint256 amount) external {
        // Skip when the deployment does not exist.
        if (!rushLauncherStore.deploymentExists(pair)) {
            return;
        }
        // Bound the `amount` to the range (1 wei, 10k WETH).
        amount = bound(amount, 1 wei, 10_000 ether);
        // Give required assets to this contract.
        deal({ token: weth, to: address(this), give: amount });
        // Swap the WETH for RushERC20.
        _swapWETHForRushERC20(pair, amount);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ INTERNAL FUNCTIONS +|=------------------------------ //

    function _launchERC20(LaunchParams memory params, bytes32 kind, bytes memory initData) internal {
        // Skip when the `originator` address is the zero address or the WETH address.
        if (params.originator == address(0) || params.originator == weth) {
            return;
        }
        // Bound the `maxSupply` to the range (MIN_SUPPLY_LIMIT, MAX_SUPPL_LIMITY).
        params.maxSupply = bound(params.maxSupply, rushLauncher.MIN_SUPPLY_LIMIT(), rushLauncher.MAX_SUPPLY_LIMIT());
        // Bound the `liquidityAmount` to the range (MIN_DEPLOYMENT_AMOUNT, MAX_DEPLOYMENT_AMOUNT).
        params.liquidityAmount = bound(
            params.liquidityAmount, liquidityDeployer.MIN_DEPLOYMENT_AMOUNT(), liquidityDeployer.MAX_DEPLOYMENT_AMOUNT()
        );
        // Bound the `liquidityDuration` to the range (MIN_DURATION, MAX_DURATION).
        params.liquidityDuration =
            bound(params.liquidityDuration, liquidityDeployer.MIN_DURATION(), liquidityDeployer.MAX_DURATION());
        // Supply LiquidityPool with required liquidity.
        uint256 wethReserve = IERC20(weth).balanceOf(address(liquidityPool));
        if (wethReserve < liquidityDeployer.MAX_DEPLOYMENT_AMOUNT()) {
            uint256 amount = liquidityDeployer.MAX_DEPLOYMENT_AMOUNT() - wethReserve;
            // Give required assets.
            deal({ token: weth, to: address(this), give: amount });
            // Approve the LiquidityPool to spend the assets.
            approveFrom({ asset: weth, owner: address(this), spender: address(liquidityPool), amount: amount });
            // Deposit the assets into the LiquidityPool.
            liquidityPool.deposit(amount, address(this));
            // Take a snapshot of the total assets.
            liquidityPool.takeSnapshotTotalAssets();
        }
        // Supply the fee.
        (uint256 totalFee,) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: params.liquidityDuration,
                newLiquidity: params.liquidityAmount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: liquidityDeployer.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.lastSnapshotTotalAssets()
            })
        );
        // Add the excess fee if enabled.
        if (params.hasExcessFee) {
            // Bound the `excessFeeAmount` to the range (0.0001 ETH, 0.1 ETH).
            params.excessFeeAmount = bound(params.excessFeeAmount, 0.0001 ether, 0.1 ether);
            totalFee += params.excessFeeAmount;
        }
        // Give the required ETH to this contract.
        vm.deal({ account: address(this), newBalance: totalFee });
        // Launch the RushERC20 token with its liquidity.
        (, address uniV2Pair) = rushLauncher.launch{ value: totalFee }(
            RL.LaunchParams({
                originator: params.originator,
                kind: kind,
                name: params.name,
                symbol: params.symbol,
                maxSupply: params.maxSupply,
                data: initData,
                liquidityAmount: params.liquidityAmount,
                liquidityDuration: params.liquidityDuration,
                maxTotalFee: type(uint256).max
            })
        );
        // Push the deployment to the store.
        rushLauncherStore.pushDeployment(uniV2Pair);
    }

    function _swapWETHForRushERC20(address pair, uint256 amount) internal {
        // Transfer the assets to the pair.
        IERC20(weth).transfer(pair, amount);
        // Calculate the expected amount of RushERC20 to receive.
        bool isToken0WETH = IUniswapV2Pair(pair).token0() == weth;
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 wethReserve, uint256 rushERC20Reserve) = isToken0WETH ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountInWithFee = amount * 997;
        uint256 numerator = amountInWithFee * rushERC20Reserve;
        uint256 denominator = wethReserve * 1000 + amountInWithFee;
        uint256 maxRushERC20Amount = numerator / denominator;
        // Skip when the expected amount is zero.
        if (maxRushERC20Amount == 0) {
            return;
        }
        // Swap the WETH for RushERC20.
        IUniswapV2Pair(pair).swap(
            isToken0WETH ? 0 : maxRushERC20Amount, isToken0WETH ? maxRushERC20Amount : 0, address(this), new bytes(0)
        );
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
