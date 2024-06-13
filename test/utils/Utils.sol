// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { StdUtils } from "forge-std/src/StdUtils.sol";
import { Vm } from "forge-std/src/Vm.sol";

abstract contract Utils is StdUtils {
    /// @dev The virtual address of the Foundry VM.
    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    /// @dev An instance of the Foundry VM, which contains cheatcodes for testing.
    Vm private constant vm = Vm(VM_ADDRESS);
}
