// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

struct Users {
    // Default admin for all protocol contracts.
    address payable admin;
    // Asset manager role assignee.
    address payable assetManager;
    // Regular user.
    address payable eve;
    // Launcher role assignee.
    address payable launcher;
    // Liquidity recipient.
    address payable recipient;
    // Reserve to receive fees.
    address payable reserve;
    // Router role assignee.
    address payable router;
    // Default message sender.
    address payable sender;
}
