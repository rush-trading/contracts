// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushRouter } from "src/periphery/RushRouter.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployRushRouter is BaseScript {
    function run(IRushLauncher rushLauncher) public virtual broadcast returns (RushRouter rushRouter) {
        rushRouter = new RushRouter({ rushLauncher_: rushLauncher });
    }
}
