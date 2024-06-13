// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

struct Users {
    // Default admin for all protocol contracts.
    address payable admin;
    // Asset manager.
    address payable assetManager;
    // Liquidity deployer.
    address payable liquidityDeployer;
    // Token deployer.
    address payable tokenDeployer;
}
