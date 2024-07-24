// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";

import { Invariant_Test } from "./Invariant.t.sol";

import { RushLauncherHandler } from "./handlers/RushLauncherHandler.sol";
import { RushLauncherStore } from "./stores/RushLauncherStore.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { LD } from "src/types/DataTypes.sol";
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
        excludeSender(address(liquidityDeployer));
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

        liquidityPool = new LiquidityPool({ aclManager_: address(aclManager), asset_: address(wethMock) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });

        liquidityDeployer = new LiquidityDeployer({
            aclManager_: address(aclManager),
            earlyUnwindThreshold_: defaults.EARLY_UNWIND_THRESHOLD(),
            feeCalculator_: address(feeCalculator),
            liquidityPool_: address(liquidityPool),
            maxDeploymentAmount_: defaults.MAX_LIQUIDITY_AMOUNT(),
            maxDuration_: defaults.MAX_LIQUIDITY_DURATION(),
            minDeploymentAmount_: defaults.MIN_LIQUIDITY_AMOUNT(),
            minDuration_: defaults.MIN_LIQUIDITY_DURATION(),
            reserve_: users.reserve,
            reserveFactor_: defaults.RESERVE_FACTOR()
        });
        vm.label({ account: address(liquidityDeployer), newLabel: "LiquidityDeployer" });

        rushERC20Factory = new RushERC20Factory({ aclManager_: address(aclManager) });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });

        uniswapV2Factory = IUniswapV2Factory(deployUniswapV2Factory(users.recipient));
        vm.label({ account: address(uniswapV2Factory), newLabel: "UniswapV2Factory" });

        rushLauncher = new RushLauncher({
            baseAsset_: address(wethMock),
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: defaults.RUSH_ERC20_MAX_SUPPLY(),
            minSupplyLimit_: defaults.RUSH_ERC20_MIN_SUPPLY(),
            rushERC20Factory_: address(rushERC20Factory),
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
        aclManager.addRushCreator({ account: address(rushLauncher) });
        aclManager.addLiquidityDeployer({ account: address(rushLauncher) });
        aclManager.addAssetManager({ account: address(liquidityDeployer) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ INVARIANTS +|=---------------------------------- //

    function invariant_alwaysCanUnwindAtDeadline() external {
        // Unwind at the deadline.
        _unwindDeadline();
    }

    function invariant_alwaysCanUnwindDeadlineIfUniswapFeeOn() external {
        // Set FeeToSetter as the caller.
        resetPrank({ msgSender: uniswapV2Factory.feeToSetter() });

        // Set Uniswap fee on.
        uniswapV2Factory.setFeeToSetter(users.recipient);

        // Unwind at the deadline.
        _unwindDeadline();
    }

    function invariant_alwaysCanUnwindEmergency() external {
        // Emergency unwind.
        _unwindEmergency();
    }

    function invariant_alwaysCanUnwindEmergencyIfUniswapFeeOn() external {
        // Set FeeToSetter as the caller.
        resetPrank({ msgSender: uniswapV2Factory.feeToSetter() });

        // Set Uniswap fee on.
        uniswapV2Factory.setFeeToSetter(users.recipient);

        // Emergency unwind.
        _unwindEmergency();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

    function _unwindDeadline() internal {
        uint256 id = rushLauncherStore.nextDeploymentId();
        for (uint256 i = 0; i < id; i++) {
            address uniV2Pair = rushLauncherStore.deployments(i);
            // Skip the entire test if the first pair is address(0).
            if (uniV2Pair == address(0)) {
                return;
            }

            // Set time to be at the deadline.
            LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
            vm.warp(liquidityDeployment.deadline);

            // Should be able to unwind.
            liquidityDeployer.unwindLiquidity(uniV2Pair);
        }
    }

    function _unwindEmergency() internal {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });

        // Pause the contract.
        liquidityDeployer.pause();

        uint256 id = rushLauncherStore.nextDeploymentId();
        address[] memory uniV2Pairs = new address[](id);
        for (uint256 i = 0; i < id; i++) {
            address uniV2Pair = rushLauncherStore.deployments(i);
            // Skip the entire test if the first pair is address(0).
            if (uniV2Pair == address(0)) {
                return;
            }
            uniV2Pairs[i] = uniV2Pair;
        }

        // Should be able to unwind.
        liquidityDeployer.unwindLiquidityEMERGENCY(uniV2Pairs);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
