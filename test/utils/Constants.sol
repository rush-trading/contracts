// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

abstract contract Constants {
    bytes32 internal constant ADMIN_ROLE = 0x00;
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    bytes32 internal constant LAUNCHER_ROLE = keccak256("LAUNCHER_ROLE");
}
