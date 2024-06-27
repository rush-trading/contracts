// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Utils } from "test/utils/Utils.sol";
import { Constants } from "test/utils/Constants.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Constants, StdCheats, Utils, StdUtils {
    // #region ----------------------------------=|+ MODIFIERS +|=----------------------------------- //

    /// @dev Makes the provided sender the caller.
    modifier useNewSender(address sender) {
        resetPrank(sender);
        _;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Approves the spender to spend the owner's assets.
    function approveFrom(address token, address owner, address spender, uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        resetPrank(owner);
        IERC20(token).approve(spender, amount);
        resetPrank(caller);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
