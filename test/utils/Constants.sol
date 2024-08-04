// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

abstract contract Constants {
    bytes32 internal constant ADMIN_ROLE = 0x00;
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    bytes32 internal constant LAUNCHER_ROLE = keccak256("LAUNCHER_ROLE");
    bytes32 internal constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 internal constant RUSH_ERC20_BASIC_KIND = 0xcac1368504ad87313cdd2f6dcf30ca9b9464d5bcb5a8a0613bbe9dce5b33a365;
    string internal constant RUSH_ERC20_NAME = "GoodRush";
    string internal constant RUSH_ERC20_SYMBOL = "GR";
    bytes4 internal constant UNKNOWN_INTERFACE_ID = 0xdeadbeef;
}
