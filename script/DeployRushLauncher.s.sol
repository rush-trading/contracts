// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployRushLauncher is BaseScript {
    function run(
        address liquidityDeployer,
        uint256 maxSupplyLimit,
        uint256 minSupplyLimit,
        address rushERC20Factory,
        address uniswapV2Factory
    )
        public
        virtual
        broadcast
        returns (IRushLauncher rushLauncher)
    {
        rushLauncher = new RushLauncher({
            liquidityDeployer_: liquidityDeployer,
            maxSupplyLimit_: maxSupplyLimit,
            minSupplyLimit_: minSupplyLimit,
            rushERC20Factory_: rushERC20Factory,
            uniswapV2Factory_: uniswapV2Factory
        });
    }
}
