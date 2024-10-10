// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployTokenRushERC20Taxable is BaseScript {
    function run() public virtual broadcast returns (RushERC20Taxable rushERC20Taxable) {
        rushERC20Taxable = new RushERC20Taxable();
    }
}
