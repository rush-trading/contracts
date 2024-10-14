// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouter } from "src/periphery/RushRouter.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployACLManager is BaseScript {
    // WETH on Base
    address public constant ASSET = 0x4200000000000000000000000000000000000006;

    // Uni v2 factory on Base
    address public constant UNISWAP_V2_FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;

    // Admin address
    address public admin = broadcaster;

    // Reserve address
    address public reserve = broadcaster;

    //////////////////////////////////////////////////////////////

    // 1 WETH max deposit - suggest 250 WETH
    uint256 public maxTotalDeposits = 1 * 1e18;

    // 100% annual base fee rate - looks good
    uint256 public baseFeeRate = 31_709_791_983;

    // 60% optimal utilization - looks good
    uint256 public optimalUtilizationRatio = 6e17;

    // ~1% annual slope when U is less than U_optimal - maybe bump it a bit
    uint256 public rateSlope1 = 317_097_919;

    // ~75% annual slope when U is greater than U_optimal - looks good
    uint256 public rateSlope2 = 23_782_343_987;

    // 5 WETH for early unwind threshold - good to go imo, in line with Pump
    uint256 public earlyUnwindThreshold = 5 * 1e18;

    // Max deployment amount is 0.01 WETH - suggest 5 ETH
    uint256 public maxDeploymentAmount = 1e16;

    // Min deployment amount is 0.001 WETH - everything less than $1k has a 'This pair has very little liquidity' msg
    // on Dexscreener, 0.05 ETH on G8keep, suggest no less than 0.05 ETH
    uint256 public minDeploymentAmount = 1e15;

    // Max deployment duration is 10 hrs - suggest 1d
    uint256 public maxDuration = 10 hours;

    // Min deployment duration is 1 minute - suggest 1h
    uint256 public minDuration = 1 minutes;

    // 10% reserve factor - suggest 15-20%, in line with Compound/Aave
    uint256 public reserveFactor = 1e17;

    // Max rushERC20 supply is 100B - suggest 100T
    uint256 public maxSupplyLimit = 100_000_000_000 * 1e18;

    // Min rushERC20 supply is 1M - suggest 1B
    uint256 public minSupplyLimit = 1_000_000 * 1e18;

    function run() public virtual broadcast {
        ACLManager aclManager = new ACLManager({ admin_: admin });

        LiquidityPool liquidityPool =
            new LiquidityPool({ aclManager_: address(aclManager), asset_: ASSET, maxTotalDeposits_: maxTotalDeposits });

        RushERC20Factory rushERC20Factory = new RushERC20Factory({ aclManager_: address(aclManager) });

        FeeCalculator feeCalculator = new FeeCalculator({
            baseFeeRate: baseFeeRate,
            optimalUtilizationRatio: optimalUtilizationRatio,
            rateSlope1: rateSlope1,
            rateSlope2: rateSlope2
        });

        LiquidityDeployer liquidityDeployer = new LiquidityDeployer({
            aclManager_: address(aclManager),
            earlyUnwindThreshold_: earlyUnwindThreshold,
            feeCalculator_: address(feeCalculator),
            liquidityPool_: address(liquidityPool),
            maxDeploymentAmount_: maxDeploymentAmount,
            maxDuration_: maxDuration,
            minDeploymentAmount_: minDeploymentAmount,
            minDuration_: minDuration,
            reserve_: reserve,
            reserveFactor_: reserveFactor
        });

        RushLauncher rushLauncher = new RushLauncher({
            aclManager_: address(aclManager),
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: maxSupplyLimit,
            minSupplyLimit_: minSupplyLimit,
            rushERC20Factory_: address(rushERC20Factory),
            uniswapV2Factory_: UNISWAP_V2_FACTORY
        });

        RushRouter rushRouter = new RushRouter({ rushLauncher_: IRushLauncher(rushLauncher) });

        aclManager.addAssetManager({ account: address(liquidityDeployer) });

        aclManager.addLauncher({ account: address(rushLauncher) });

        aclManager.addRouter({ account: address(rushRouter) });

        RushERC20Basic rushERC20Basic = new RushERC20Basic();

        RushERC20Taxable rushERC20Taxable = new RushERC20Taxable();

        rushERC20Factory.addTemplate(address(rushERC20Basic));

        rushERC20Factory.addTemplate(address(rushERC20Taxable));
    }
}
