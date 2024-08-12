// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import {IRushERC20} from "./IRushERC20.sol";

interface IRushERC20Taxable is IRushERC20 {
    function addExchangePool(address exchangePool) external;
    function removeExchangePool(address exchangePool) external;
    function addExemption(address exemption) external;
    function removeExemption(address exemption) external;
    function taxBasisPoints() external returns (uint256 tax);
}