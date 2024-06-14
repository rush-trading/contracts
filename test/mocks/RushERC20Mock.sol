// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title RushERC20Mock
 */
contract RushERC20Mock is RushERC20Abstract {
    /// @inheritdoc IERC20
    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC20
    function approve(address, uint256) public pure override returns (bool) {
        return true;
    }

    /// @inheritdoc IERC20
    function balanceOf(address) public pure override returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @inheritdoc IRushERC20
    function description() public pure override returns (string memory) {
        return "RushERC20Mock";
    }

    /// @inheritdoc IRushERC20
    function initialize(
        string calldata,
        string calldata,
        uint256,
        address,
        bytes calldata
    )
        public
        override
        initializer
    { }

    /// @inheritdoc IERC20Metadata
    function name() public pure override returns (string memory) {
        return "Mock Token";
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public pure override returns (string memory) {
        return "MOCK";
    }

    /// @inheritdoc IERC20
    function totalSupply() public pure override returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC20
    function transfer(address, uint256) public pure override returns (bool) {
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return true;
    }

    /// @inheritdoc IRushERC20
    function version() public pure override returns (uint256) {
        return 42;
    }
}
