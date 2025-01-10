// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushRouter } from "src/periphery/RushRouter.sol";
import { IRushSmartLock } from "src/RushSmartLock.sol";
import { LD } from "src/types/DataTypes.sol";
import { BaseScript } from "./Base.s.sol";

contract UpgradeMaster is BaseScript {
    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct RunReturnType {
        FeeCalculator feeCalculator;
        LiquidityDeployer liquidityDeployer;
        RushLauncher rushLauncher;
        RushRouter rushRouter;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ CONFIGURABLE CONSTANTS +|=---------------------------- //

    // 100% annual base fee rate - looks good
    uint256 internal constant BASE_FEE_RATE = 31_709_791_983;

    // 5 WETH for early unwind threshold - good to go imo, 2x less than Pump
    uint256 internal constant EARLY_UNWIND_THRESHOLD = 2.5 ether;

    // Max deployment amount is 0.01 WETH - suggest 2.5 ETH
    uint256 internal constant MAX_DEPLOYMENT_AMOUNT = 2.5 ether;

    // Max deployment duration is 10 hrs - suggest 1d
    uint256 internal constant MAX_DURATION = 24 hours;

    // Max rushERC20 supply is 100B - suggest 100T
    uint256 internal constant MAX_SUPPLY_LIMIT = 100_000_000_000e18;

    // Min deployment amount is 0.001 WETH - everything less than $1k has a 'This pair has very little liquidity' msg
    // on Dexscreener, seems like 0.5 ETH is our go-to option
    uint256 internal constant MIN_DEPLOYMENT_AMOUNT = 0.5 ether;

    // Min deployment duration is 1 minute - suggest 1h
    uint256 internal constant MIN_DURATION = 1 hours;

    // Min rushERC20 supply is 1M - suggest 1B
    uint256 internal constant MIN_SUPPLY_LIMIT = 1_000_000e18;

    // 60% optimal utilization - looks good
    uint256 internal constant OPTIMAL_UTILIZATION_RATIO = 0.6e18;

    // ~1% annual slope when U is less than U_optimal - maybe bump it a bit
    uint256 internal constant RATE_SLOPE_1 = 317_097_919;

    // ~75% annual slope when U is greater than U_optimal - looks good
    uint256 internal constant RATE_SLOPE_2 = 23_782_343_987;

    // 10% reserve factor - suggest 15-20%, in line with Compound/Aave
    uint256 internal constant RESERVE_FACTOR = 0.2e18;

    // 0.5% reward factor for originator rewards
    uint256 internal constant REWARD_FACTOR = 0.005e18;

    // 5% surplus factor
    uint256 internal constant SURPLUS_FACTOR = 0.05e18;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ STATIC CONSTANTS +|=------------------------------- //

    // Uni v2 factory on Base
    address internal constant UNISWAP_V2_FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    // Reserve address
    address internal immutable RESERVE;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor() BaseScript() {
        RESERVE = broadcaster;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    /// @notice Deploys all contracts
    function run(
        address aclManager,
        address liquidityPool,
        address rushERC20Factory,
        address rushSmartLock,
        address oldLiquidityDeployer,
        address oldRushLauncher,
        address oldRushRouter
    )
        public
        virtual
        broadcast
        returns (RunReturnType memory runReturnData)
    {
        // Deploy FeeCalculator
        runReturnData.feeCalculator = new FeeCalculator({
            baseFeeRate: BASE_FEE_RATE,
            optimalUtilizationRatio: OPTIMAL_UTILIZATION_RATIO,
            rateSlope1: RATE_SLOPE_1,
            rateSlope2: RATE_SLOPE_2
        });

        // Deploy LiquidityDeployer
        runReturnData.liquidityDeployer = new LiquidityDeployer(
            LD.ConstructorParam({
                aclManager_: aclManager,
                earlyUnwindThreshold_: EARLY_UNWIND_THRESHOLD,
                feeCalculator_: address(runReturnData.feeCalculator),
                liquidityPool_: liquidityPool,
                maxDeploymentAmount_: MAX_DEPLOYMENT_AMOUNT,
                maxDuration_: MAX_DURATION,
                minDeploymentAmount_: MIN_DEPLOYMENT_AMOUNT,
                minDuration_: MIN_DURATION,
                reserve_: RESERVE,
                reserveFactor_: RESERVE_FACTOR,
                rewardFactor_: REWARD_FACTOR,
                rushSmartLock_: rushSmartLock,
                surplusFactor_: SURPLUS_FACTOR
            })
        );

        // Set LiquidityDeployer address in RushSmartLock
        IRushSmartLock(rushSmartLock).setLiquidityDeployer(address(runReturnData.liquidityDeployer));

        // Deploy RushLauncher
        runReturnData.rushLauncher = new RushLauncher({
            aclManager_: aclManager,
            liquidityDeployer_: address(runReturnData.liquidityDeployer),
            maxSupplyLimit_: MAX_SUPPLY_LIMIT,
            minSupplyLimit_: MIN_SUPPLY_LIMIT,
            rushERC20Factory_: rushERC20Factory,
            uniswapV2Factory_: UNISWAP_V2_FACTORY
        });

        // Deploy RushRouter
        runReturnData.rushRouter = new RushRouter({ rushLauncher_: runReturnData.rushLauncher });

        // Set ACLManager roles
        ACLManager(aclManager).addAssetManager({ account: address(runReturnData.liquidityDeployer) });
        ACLManager(aclManager).addLauncher({ account: address(runReturnData.rushLauncher) });
        ACLManager(aclManager).addRouter({ account: address(runReturnData.rushRouter) });

        ACLManager(aclManager).removeAssetManager({ account: address(oldLiquidityDeployer) });
        ACLManager(aclManager).removeLauncher({ account: address(oldRushLauncher) });
        ACLManager(aclManager).removeRouter({ account: address(oldRushRouter) });
    }
}
