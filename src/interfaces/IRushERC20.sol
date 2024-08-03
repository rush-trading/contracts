// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRushERC20
 * @notice The Rush ERC20 token.
 */
interface IRushERC20 is IERC165, IERC20Metadata {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when the token contract is initialized.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param maxSupply The maximum supply of the token.
     * @param recipient The recipient of the minted tokens.
     * @param data Additional data for the token initialization.
     */
    event Initialize(
        string indexed name, string indexed symbol, uint256 maxSupply, address indexed recipient, bytes data
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice Returns the description of the token implementation.
    function description() external view returns (string memory);

    /// @notice Returns the version of the token implementation.
    function version() external view returns (uint256);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Initializes the token contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param maxSupply The maximum supply of the token.
     * @param recipient The recipient of the minted tokens.
     * @param data Additional data for the token initialization.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        address recipient,
        bytes calldata data
    )
        external;

    // #endregion ----------------------------------------------------------------------------------- //
}
