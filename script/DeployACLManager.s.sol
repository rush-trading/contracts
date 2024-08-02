// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IACLManager } from "src/interfaces/IACLManager.sol";
import { ACLManager } from "src/ACLManager.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployACLManager is BaseScript {
    function run(address admin) public virtual broadcast returns (IACLManager aclManager) {
        aclManager = new ACLManager({ admin_: admin });
    }
}
