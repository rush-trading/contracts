// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployFeeCalculator is BaseScript {
    function run(
        uint256 baseFeeRate,
        uint256 optimalUtilizationRatio,
        uint256 rateSlope1,
        uint256 rateSlope2
    )
        public
        virtual
        broadcast
        returns (IFeeCalculator feeCalculator)
    {
        feeCalculator = new FeeCalculator({
            baseFeeRate: baseFeeRate,
            optimalUtilizationRatio: optimalUtilizationRatio,
            rateSlope1: rateSlope1,
            rateSlope2: rateSlope2
        });
    }
}
