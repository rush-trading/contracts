// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Donatable } from "src/tokens/RushERC20Donatable.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployTokenRushERC20Donatable is BaseScript {
    function run() public virtual broadcast returns (RushERC20Donatable rushERC20Donatable) {
        rushERC20Donatable = new RushERC20Donatable();
    }
}
