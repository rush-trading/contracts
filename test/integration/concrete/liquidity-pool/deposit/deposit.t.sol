// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Deposit_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_GivenMaxTotalDepositsAreExceeded() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Give required WETH to Eve.
        uint256 amount = defaults.MAX_TOTAL_DEPOSITS() + 1;
        deal({ token: address(wethMock), to: users.eve, give: amount });

        // Approve LiquidityPool to spend WETH on behalf of Eve.
        wethMock.approve(address(liquidityPool), amount);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_MaxTotalDepositsExceeded.selector));
        liquidityPool.deposit({ assets: amount, receiver: users.recipient });
    }

    function test_GivenMaxTotalDepositsAreNotExceeded() external {
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Give required WETH to Sender.
        uint256 amount = defaults.MAX_TOTAL_DEPOSITS();
        deal({ token: address(wethMock), to: users.sender, give: amount });

        // Approve LiquidityPool to spend WETH on behalf of Sender.
        wethMock.approve(address(liquidityPool), amount);

        // Expect the relevant event to be emitted.
        vm.expectEmit({
            emitter: address(liquidityPool),
            checkTopic1: true,
            checkTopic2: true,
            checkTopic3: false,
            checkData: false
        });
        emit Deposit({ sender: users.sender, owner: users.recipient, assets: 0, shares: 0 });

        // Deposit the WETH.
        liquidityPool.deposit({ assets: amount, receiver: users.recipient });
    }
}
