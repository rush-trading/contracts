// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

struct Users {
    // Default admin for all protocol contracts.
    address payable admin;
    // Asset manager.
    address payable assetManager;
    // Malicious user.
    address payable eve;
    // Launcher.
    address payable launcher;
    // Liquidity recipient.
    address payable recipient;
    // Reserve to receive fees.
    address payable reserve;
    // Default message sender.
    address payable sender;
}
