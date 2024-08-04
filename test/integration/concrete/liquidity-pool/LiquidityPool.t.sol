// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Integration_Test } from "test/integration/Integration.t.sol";

contract LiquidityPool_Integration_Concrete_Test is Integration_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Dispatches assets from the LiquidityPool to the Recipient.
    function dispatchAsset(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.assetManager });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
