// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

struct Users {
    // Default admin for all protocol contracts.
    address payable admin;
    // Asset manager.
    address payable assetManager;
    // Malicious user.
    address payable eve;
    // Liquidity deployer.
    address payable liquidityDeployer;
    // Default message sender.
    address payable sender;
    // Token deployer.
    address payable tokenDeployer;
}
