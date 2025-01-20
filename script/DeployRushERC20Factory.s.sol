// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IRushERC20Factory } from "src/interfaces/IRushERC20Factory.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployRushERC20Factory is BaseScript {
    function run(address aclManager) public virtual broadcast returns (IRushERC20Factory rushERC20Factory) {
        rushERC20Factory = new RushERC20Factory({ aclManager_: aclManager });
    }
}
