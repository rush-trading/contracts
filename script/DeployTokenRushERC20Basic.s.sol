// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployTokenRushERC20Basic is BaseScript {
    function run() public virtual broadcast returns (RushERC20Basic rushERC20Basic) {
        rushERC20Basic = new RushERC20Basic();
    }
}
