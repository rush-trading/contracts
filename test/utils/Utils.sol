// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CommonBase } from "forge-std/src/Base.sol";

abstract contract Utils is CommonBase {
    /// @dev Approves the spender to spend the owner's tokens.
    function approveFrom(address asset, address owner, address spender, uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        resetPrank(owner);
        IERC20(asset).approve(spender, amount);
        resetPrank(caller);
    }

    /// @dev Stops the active prank and sets a new one.
    function resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }
}
