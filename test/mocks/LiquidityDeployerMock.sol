// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { LD } from "src/types/DataTypes.sol";

contract LiquidityDeployerMock {
    /// @dev A mapping of liquidity deployments.
    mapping(address uniV2Pair => LD.LiquidityDeployment) internal _liquidityDeployments;

    function getLiquidityDeployment(address uniV2Pair) external view returns (LD.LiquidityDeployment memory) {
        return _liquidityDeployments[uniV2Pair];
    }

    function setIsUnwound(address uniV2Pair, bool isUnwound) external {
        _liquidityDeployments[uniV2Pair].isUnwound = isUnwound;
    }

    function setIsUnwindThresholdMet(address uniV2Pair, bool isUnwindThresholdMet) external {
        _liquidityDeployments[uniV2Pair].isUnwindThresholdMet = isUnwindThresholdMet;
    }
}
