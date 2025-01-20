// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { Constants } from "test/utils/Constants.sol";
import { Utils } from "test/utils/Utils.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Constants, StdCheats, Utils, StdUtils {
    // #region ----------------------------------=|+ MODIFIERS +|=----------------------------------- //

    /// @dev Makes the provided sender the caller.
    modifier useNewSender(address sender) {
        resetPrank(sender);
        _;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
