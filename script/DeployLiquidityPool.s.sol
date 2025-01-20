// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployLiquidityPool is BaseScript {
    function run(
        address aclManager,
        address asset,
        uint256 maxTotalDeposits
    )
        public
        virtual
        broadcast
        returns (ILiquidityPool liquidityPool)
    {
        liquidityPool =
            new LiquidityPool({ aclManager_: aclManager, asset_: asset, maxTotalDeposits_: maxTotalDeposits });
    }
}
