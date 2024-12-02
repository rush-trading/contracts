// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

abstract contract Constants {
    bytes32 internal constant ADMIN_ROLE = 0x00;
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    bytes32 internal constant LAUNCHER_ROLE = keccak256("LAUNCHER_ROLE");
    bytes32 internal constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 internal constant RUSH_ERC20_BASIC_KIND = 0xcac1368504ad87313cdd2f6dcf30ca9b9464d5bcb5a8a0613bbe9dce5b33a365;
    bytes32 internal constant RUSH_ERC20_TAXABLE_KIND =
        0xfa3f84d263ed55bc45f8e22cdb3a7481292f68ee28ab539b69876f8dc1535b40;
    bytes32 internal constant RUSH_ERC20_DONATABLE_KIND =
        0xf3276aaa36076beebbabfe73c27d58e731e1c37a0f9ab8753064868d7dbdf469;
    string internal constant RUSH_ERC20_NAME = "GoodRush";
    string internal constant RUSH_ERC20_SYMBOL = "GR";
    bytes4 internal constant UNKNOWN_INTERFACE_ID = 0xdeadbeef;
}
