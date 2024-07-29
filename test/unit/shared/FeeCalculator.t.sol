// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { FeeCalculator } from "src/FeeCalculator.sol";

import { Base_Test } from "test/Base.t.sol";

contract FeeCalculator_Unit_Shared_Test is Base_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        feeCalculator = new FeeCalculator({
            baseFeeRate: defaults.BASE_FEE_RATE(),
            optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO(),
            rateSlope1: defaults.RATE_SLOPE_1(),
            rateSlope2: defaults.RATE_SLOPE_2()
        });
        vm.label({ account: address(feeCalculator), newLabel: "FeeCalculator" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
