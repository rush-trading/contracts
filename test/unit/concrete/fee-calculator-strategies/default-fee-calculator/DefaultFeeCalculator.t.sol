// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { DefaultFeeCalculator } from "src/fee-calculator/strategies/DefaultFeeCalculator.sol";

import { Base_Test } from "test/Base.t.sol";

contract DefaultFeeCalculator_Unit_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    /// @dev Conditionally deploys {SablierV2Comptroller} normally or from a source precompiled with `--via-ir`.
    function deploy() internal {
        feeCalculator = new DefaultFeeCalculator({
            baseFeeRate: DEFAULT_BASE_FEE_RATE,
            optimalUtilizationRatio: DEFAULT_OPTIMAL_UTILIZATION_RATIO,
            rateSlope1: DEFAULT_RATE_SLOPE1,
            rateSlope2: DEFAULT_RATE_SLOPE2
        });
        vm.label({ account: address(feeCalculator), newLabel: "FeeCalculator" });
    }
}
