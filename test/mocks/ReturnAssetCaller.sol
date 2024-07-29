// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";

/**
 * @title ReturnAssetCaller
 */
contract ReturnAssetCaller is IReturnAssetCallback {
    /// @inheritdoc IReturnAssetCallback
    function onReturnAsset(address, uint256, bytes calldata) external pure override { }
}
