// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_LiquidityPool_Integration_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Construct the contract.
        LiquidityPool constructedLiquidityPool =
            new LiquidityPool({ aclManager_: address(aclManager), asset_: address(wethMock) });

        // Assert that the values were set correctly.
        address actualACLManager = constructedLiquidityPool.ACL_MANAGER();
        address expectedACLManager = address(aclManager);
        assertEq(actualACLManager, expectedACLManager, "ACL_MANAGER");

        string memory actualName = constructedLiquidityPool.name();
        string memory expectedName = string("Rush Wrapped Ether Liquidity Pool");
        assertEq(actualName, expectedName, "name");

        string memory actualSymbol = constructedLiquidityPool.symbol();
        string memory expectedSymbol = string("rWETH");
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }
}
