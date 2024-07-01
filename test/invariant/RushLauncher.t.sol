// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { LiquidityDeployerWETH } from "src/LiquidityDeployerWETH.sol";

import { Invariant_Test } from "./Invariant.t.sol";

import { RushLauncherHandler } from "./handlers/RushLauncherHandler.sol";
import { RushLauncherStore } from "./stores/RushLauncherStore.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";

/// @dev Invariant tests for {RushLauncher}.
contract RushLauncher_Invariant_Test is Invariant_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    RushLauncher internal rushLauncher;
    RushLauncherHandler internal rushLauncherHandler;
    RushLauncherStore internal rushLauncherStore;
    IUniswapV2Factory internal uniswapV2Factory;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Invariant_Test.setUp();
        deploy();
        grantRoles();

        // Add the RushERC20Basic template to the RushERC20Factory.
        addTemplate(address(new RushERC20Basic()));

        // Target the RushLauncher handler for invariant testing.
        targetContract(address(rushLauncherHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(feeCalculator));
        excludeSender(address(liquidityDeployerWETH));
        excludeSender(address(liquidityPool));
        excludeSender(address(rushERC20Factory));
        excludeSender(address(rushLauncher));
        excludeSender(address(rushLauncherStore));
        excludeSender(address(uniswapV2Factory));
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        feeCalculator = new FeeCalculator({
            baseFeeRate: defaults.BASE_FEE_RATE(),
            optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO(),
            rateSlope1: defaults.RATE_SLOPE1(),
            rateSlope2: defaults.RATE_SLOPE2()
        });
        vm.label({ account: address(feeCalculator), newLabel: "FeeCalculator" });

        liquidityPool = new LiquidityPool({ admin_: users.admin, asset_: address(wethMock) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });

        liquidityDeployerWETH = new LiquidityDeployerWETH({
            admin_: users.admin,
            earlyUnwindThreshold_: defaults.EARLY_UNWIND_THRESHOLD(),
            feeCalculator_: address(feeCalculator),
            liquidityPool_: address(liquidityPool),
            maxDeploymentAmount_: defaults.MAX_LIQUIDITY_AMOUNT(),
            maxDuration_: defaults.MAX_LIQUIDITY_DURATION(),
            minDeploymentAmount_: defaults.MIN_LIQUIDITY_AMOUNT(),
            minDuration_: defaults.MIN_LIQUIDITY_DURATION(),
            reserve_: address(users.reserve),
            reserveFactor_: defaults.RESERVE_FACTOR()
        });
        vm.label({ account: address(liquidityDeployerWETH), newLabel: "LiquidityDeployerWETH" });

        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });

        uniswapV2Factory = IUniswapV2Factory(deployUniswapV2Factory(users.recipient));
        vm.label({ account: address(uniswapV2Factory), newLabel: "UniswapV2Factory" });

        rushLauncher = new RushLauncher({
            baseAsset_: address(wethMock),
            erc20Factory_: rushERC20Factory,
            liquidityDeployer_: address(liquidityDeployerWETH),
            maxSupplyLimit_: defaults.TOKEN_MAX_SUPPLY(),
            minSupplyLimit_: defaults.TOKEN_MIN_SUPPLY(),
            uniswapV2Factory_: address(uniswapV2Factory)
        });
        vm.label({ account: address(rushLauncher), newLabel: "RushLauncher" });

        rushLauncherStore = new RushLauncherStore();
        vm.label({ account: address(rushLauncherStore), newLabel: "RushLauncherStore" });

        rushLauncherHandler =
            new RushLauncherHandler({ rushLauncher_: rushLauncher, rushLauncherStore_: rushLauncherStore });
        vm.label({ account: address(rushLauncherHandler), newLabel: "RushLauncherHandler" });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        rushERC20Factory.grantRole({ role: TOKEN_DEPLOYER_ROLE, account: address(rushLauncher) });
        liquidityDeployerWETH.grantRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: address(rushLauncher) });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(liquidityDeployerWETH) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ INVARIANTS +|=---------------------------------- //

    function invariant_alwaysCanUnwindAtDeadline() external {
        uint256 id = rushLauncherStore.nextDeploymentId();
        for (uint256 i = 0; i < id; i++) {
            address pair = rushLauncherStore.deployments(i);
            // Skip the entire test if the first pair is address(0).
            if (pair == address(0)) {
                return;
            }

            // Set time to be at the deadline.
            (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
            vm.warp(deadline);

            // Should be able to unwind.
            liquidityDeployerWETH.unwindLiquidity(pair);
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
