// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployLiquidityDeployer is BaseScript {
    function run(
        address aclManager,
        uint256 earlyUnwindThreshold,
        address feeCalculator,
        address liquidityPool,
        uint256 maxDeploymentAmount,
        uint256 maxDuration,
        uint256 minDeploymentAmount,
        uint256 minDuration,
        address reserve,
        uint256 reserveFactor
    )
        public
        virtual
        broadcast
        returns (ILiquidityDeployer liquidityDeployer)
    {
        liquidityDeployer = new LiquidityDeployer({
            aclManager_: aclManager,
            earlyUnwindThreshold_: earlyUnwindThreshold,
            feeCalculator_: feeCalculator,
            liquidityPool_: liquidityPool,
            maxDeploymentAmount_: maxDeploymentAmount,
            maxDuration_: maxDuration,
            minDeploymentAmount_: minDeploymentAmount,
            minDuration_: minDuration,
            reserve_: reserve,
            reserveFactor_: reserveFactor
        });
    }
}
