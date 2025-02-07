// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouterAlpha } from "src/periphery/RushRouterAlpha.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployRushRouterAlpha is BaseScript {
    function run(
        IRushLauncher rushLauncher,
        address sponsorAddress,
        address verifierAddress
    )
        public
        virtual
        broadcast
        returns (RushRouterAlpha rushRouterAlpha)
    {
        rushRouterAlpha = new RushRouterAlpha({
            rushLauncher_: rushLauncher,
            sponsorAddress_: sponsorAddress,
            verifierAddress_: verifierAddress
        });
    }
}
