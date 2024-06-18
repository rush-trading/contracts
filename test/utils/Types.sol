// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

struct Users {
    // Default admin for all protocol contracts.
    address payable admin;
    // Malicious user.
    address payable eve;
    // Liquidity deployer.
    address payable liquidityDeployer;
    // Default liquidity recipient.
    address payable recipient;
    // Reserve to receive fees.
    address payable reserve;
    // Default message sender.
    address payable sender;
    // Token deployer.
    address payable tokenDeployer;
}
