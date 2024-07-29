// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

contract BaseScript is Script {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address.
    string internal mnemonic;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Initializes the transaction broadcaster like this:
     * - If $MNEMONIC is defined, derive the broadcaster address from it.
     * - Otherwise, default to a test mnemonic.
     */
    constructor() {
        mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
        (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ MODIFIERS +|=----------------------------------- //

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
