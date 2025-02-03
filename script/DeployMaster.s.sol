// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouterAlpha } from "src/periphery/RushRouterAlpha.sol";
import { RushSmartLock } from "src/RushSmartLock.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { StakingRewards } from "src/StakingRewards.sol";
import { LD } from "src/types/DataTypes.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployMaster is BaseScript {
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

    // 1 WETH max deposit - suggest 75 WETH
    uint256 internal constant MAX_TOTAL_DEPOSITS = 75 ether;

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

    // Fee sponsor address
    address internal constant SPONSOR_ADDRESS = 0x04394453Eee246181B6c8858239d9855Be90bE8f;

    // 5% surplus factor
    uint256 internal constant SURPLUS_FACTOR = 0.05e18;

    // ECDSA verifier address
    address internal constant VERIFIER_ADDRESS = 0x86Cc1bE24CD93bDE2141027129247a0BEEF086ce;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ STATIC CONSTANTS +|=------------------------------- //

    // WETH on Base
    address internal constant ASSET = 0x4200000000000000000000000000000000000006;

    // Uni v2 factory on Base
    address internal constant UNISWAP_V2_FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    // Admin address
    address internal immutable ADMIN;

    // Reserve address
    address internal immutable RESERVE;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor() BaseScript() {
        ADMIN = broadcaster;
        RESERVE = broadcaster;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    /// @notice Deploys all contracts
    function run()
        public
        virtual
        broadcast
        returns (
            ACLManager aclManager,
            LiquidityPool liquidityPool,
            RushERC20Factory rushERC20Factory,
            FeeCalculator feeCalculator,
            LiquidityDeployer liquidityDeployer,
            RushLauncher rushLauncher,
            RushRouterAlpha rushRouterAlpha,
            RushSmartLock rushSmartLock
        )
    {
        // Deploy ACLManager
        aclManager = new ACLManager({ admin_: ADMIN });

        // Deploy LiquidityPool
        liquidityPool = new LiquidityPool({
            aclManager_: address(aclManager),
            asset_: ASSET,
            maxTotalDeposits_: MAX_TOTAL_DEPOSITS
        });

        // Deploy RushERC20Factory
        rushERC20Factory = new RushERC20Factory({ aclManager_: address(aclManager) });

        // Deploy FeeCalculator
        feeCalculator = new FeeCalculator({
            baseFeeRate: BASE_FEE_RATE,
            optimalUtilizationRatio: OPTIMAL_UTILIZATION_RATIO,
            rateSlope1: RATE_SLOPE_1,
            rateSlope2: RATE_SLOPE_2
        });

        // Deploy RushSmartLock
        rushSmartLock = new RushSmartLock({
            aclManager_: address(aclManager),
            liquidityPool_: address(liquidityPool),
            stakingRewardsImpl_: address(new StakingRewards()),
            uniswapV2Factory_: UNISWAP_V2_FACTORY
        });

        // Deploy LiquidityDeployer
        liquidityDeployer = new LiquidityDeployer(
            LD.ConstructorParam({
                aclManager_: address(aclManager),
                earlyUnwindThreshold_: EARLY_UNWIND_THRESHOLD,
                feeCalculator_: address(feeCalculator),
                liquidityPool_: address(liquidityPool),
                maxDeploymentAmount_: MAX_DEPLOYMENT_AMOUNT,
                maxDuration_: MAX_DURATION,
                minDeploymentAmount_: MIN_DEPLOYMENT_AMOUNT,
                minDuration_: MIN_DURATION,
                reserve_: RESERVE,
                reserveFactor_: RESERVE_FACTOR,
                rewardFactor_: REWARD_FACTOR,
                rushSmartLock_: address(rushSmartLock),
                surplusFactor_: SURPLUS_FACTOR
            })
        );

        // Set LiquidityDeployer address in RushSmartLock
        rushSmartLock.setLiquidityDeployer(address(liquidityDeployer));

        // Deploy RushLauncher
        rushLauncher = new RushLauncher({
            aclManager_: address(aclManager),
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: MAX_SUPPLY_LIMIT,
            minSupplyLimit_: MIN_SUPPLY_LIMIT,
            rushERC20Factory_: address(rushERC20Factory),
            uniswapV2Factory_: UNISWAP_V2_FACTORY
        });

        // Deploy RushRouterAlpha
        rushRouterAlpha = new RushRouterAlpha({
            rushLauncher_: IRushLauncher(rushLauncher),
            sponsorAddress_: SPONSOR_ADDRESS,
            verifierAddress_: VERIFIER_ADDRESS
        });

        // Set ACLManager roles
        aclManager.addAssetManager({ account: address(liquidityDeployer) });
        aclManager.addLauncher({ account: address(rushLauncher) });
        aclManager.addRouter({ account: address(rushRouterAlpha) });

        // Set RushERC20Factory templates
        RushERC20Basic rushERC20Basic = new RushERC20Basic();
        RushERC20Taxable rushERC20Taxable = new RushERC20Taxable();

        rushERC20Factory.addTemplate(address(rushERC20Basic));
        rushERC20Factory.addTemplate(address(rushERC20Taxable));
    }
}
