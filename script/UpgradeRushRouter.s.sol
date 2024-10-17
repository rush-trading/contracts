// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IACLManager } from "src/interfaces/IACLManager.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouter } from "src/periphery/RushRouter.sol";
import { BaseScript } from "./Base.s.sol";

contract UpgradeRushRouter is BaseScript {
    function run(
        IACLManager aclManager,
        IRushLauncher rushLauncher,
        RushRouter oldRushRouter
    )
        public
        virtual
        broadcast
        returns (RushRouter rushRouter)
    {
        rushRouter = new RushRouter({ rushLauncher_: rushLauncher });
        aclManager.addRouter({ account: address(rushRouter) });
        aclManager.removeRouter({ account: address(oldRushRouter) });
    }
}
