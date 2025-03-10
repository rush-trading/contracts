// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IACLManager } from "src/interfaces/IACLManager.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouterAlpha } from "src/periphery/RushRouterAlpha.sol";
import { BaseScript } from "./Base.s.sol";

contract UpgradeRushRouterAlpha is BaseScript {
    function run(
        IACLManager aclManager,
        IRushLauncher rushLauncher,
        address oldRushRouterAlpha,
        address sponsorAddress,
        address verifierAddress
    )
        public
        virtual
        broadcast
        returns (RushRouterAlpha rushRouterAlpha)
    {
        rushRouterAlpha = new RushRouterAlpha({
            sponsorAddress_: sponsorAddress,
            verifierAddress_: verifierAddress,
            rushLauncher_: rushLauncher
        });
        aclManager.addRouter({ account: address(rushRouterAlpha) });
        aclManager.removeRouter({ account: oldRushRouterAlpha });
    }
}
