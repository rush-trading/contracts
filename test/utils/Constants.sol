// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

abstract contract Constants {
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");
    bytes32 internal constant TOKEN_DEPLOYER_ROLE = keccak256("TOKEN_DEPLOYER_ROLE");

    // TODO: remove this from the Defaults contract.
    uint256 internal constant MAX_LIQUIDITY_AMOUNT = 10_000_000_000 ether; // 10B WETH
}
