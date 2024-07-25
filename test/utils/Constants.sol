// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

abstract contract Constants {
    bytes32 internal constant ADMIN_ROLE = 0x00;
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    bytes32 internal constant LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");
    bytes32 internal constant RUSH_CREATOR_ROLE = keccak256("RUSH_CREATOR_ROLE");
}
