// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushERC20_Unit_Concrete_Test } from "../RushERC20.t.sol";

contract SupportsInterface_Unit_Concrete_Test is RushERC20_Unit_Concrete_Test {
    function test_WhenInterfaceIdIsForIERC165() external view {
        bool actualSupportsInterface = rushERC20Mock.supportsInterface(type(IERC165).interfaceId);
        bool expectedSupportsInterface = true;
        assertEq(actualSupportsInterface, expectedSupportsInterface, "supportsInterface");
    }

    function test_WhenInterfaceIdIsForIRushERC20() external view {
        bool actualSupportsInterface = rushERC20Mock.supportsInterface(type(IRushERC20).interfaceId);
        bool expectedSupportsInterface = true;
        assertEq(actualSupportsInterface, expectedSupportsInterface, "supportsInterface");
    }

    function test_WhenInterfaceIdIsUnknown() external view {
        bool actualSupportsInterface = rushERC20Mock.supportsInterface(UNKNOWN_INTERFACE_ID);
        bool expectedSupportsInterface = false;
        assertEq(actualSupportsInterface, expectedSupportsInterface, "supportsInterface");
    }
}
