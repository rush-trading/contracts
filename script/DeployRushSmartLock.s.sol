// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IRushSmartLock } from "src/interfaces/IRushSmartLock.sol";
import { RushSmartLock } from "src/RushSmartLock.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployRushSmartLock is BaseScript {
    function run(
        address aclManager,
        address liquidityPool,
        address uniswapV2Factory
    )
        public
        virtual
        broadcast
        returns (IRushSmartLock rushSmartLock)
    {
        rushSmartLock = new RushSmartLock({
            aclManager_: aclManager,
            liquidityPool_: liquidityPool,
            uniswapV2Factory_: uniswapV2Factory
        });
    }
}
