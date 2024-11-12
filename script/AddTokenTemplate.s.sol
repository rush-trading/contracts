// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { BaseScript } from "./Base.s.sol";

contract AddTokenTemplate is BaseScript {
    function run(address rushERC20Factory, address rushERC20Template) public virtual broadcast {
        RushERC20Factory(rushERC20Factory).addTemplate(rushERC20Template);
    }
}
