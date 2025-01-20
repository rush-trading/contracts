// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { IACLManager } from "src/interfaces/IACLManager.sol";
import { BaseScript } from "./Base.s.sol";

contract DeployACLManager is BaseScript {
    function run(address admin) public virtual broadcast returns (IACLManager aclManager) {
        aclManager = new ACLManager({ admin_: admin });
    }
}
