// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { LD } from "src/types/DataTypes.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployLiquidityDeployer is BaseScript {
    function run(LD.ConstructorParam calldata params)
        public
        virtual
        broadcast
        returns (ILiquidityDeployer liquidityDeployer)
    {
        liquidityDeployer = new LiquidityDeployer(params);
    }
}
