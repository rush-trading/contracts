// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { LD } from "src/types/DataTypes.sol";

/**
 * @dev Extension of {ERC20} that includes a donation to a given address.
 */
abstract contract ERC20DonatableUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    // #region ------------------------------------=|+ ERRORS +|=------------------------------------ //

    /// @notice Thrown when donation has already been sent.
    error DonationAlreadySent();

    /// @notice Thrown when the pair has not been unwound yet.
    error PairNotUnwound();

    /// @notice Thrown when the unwind threshold wasn't met for unwound pair.
    error UnwindThresholdNotMet();

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    event Donation(address indexed receiver, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    /**
     * @notice Factor to calculate the donation amount.
     * @dev Represented in WAD precision (18 decimal format).
     */
    uint256 public constant DONATION_FACTOR = 0.1e18;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice Reciever of the donation.
    address public donationBeneficiary;

    /// @notice Flag to check if donation has been sent.
    bool public isDonationSent;

    /// @notice Address of the liquidity deployer.
    ILiquidityDeployer public liquidityDeployer;

    /// @notice Address of the Uniswap V2 pair for the token.
    address public uniV2Pair;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Initialize the contract with calls to parent initializers.
    function __ERC20Donatable_init(
        address _donationBeneficiary,
        address _liquidityDeployer,
        address _uniV2Pair
    )
        internal
        onlyInitializing
    {
        __ERC20Donatable_init_unchained(_donationBeneficiary, _liquidityDeployer, _uniV2Pair);
    }

    /// @dev Initialize the contract without calling parent initializers.
    function __ERC20Donatable_init_unchained(
        address _donationBeneficiary,
        address _liquidityDeployer,
        address _uniV2Pair
    )
        internal
        onlyInitializing
    {
        donationBeneficiary = _donationBeneficiary;
        liquidityDeployer = ILiquidityDeployer(_liquidityDeployer);
        uniV2Pair = _uniV2Pair;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    function donate() external {
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        if (!liquidityDeployment.isUnwound) {
            revert PairNotUnwound();
        }
        if (!liquidityDeployment.isUnwindThresholdMet) {
            revert UnwindThresholdNotMet();
        }
        if (isDonationSent) {
            revert DonationAlreadySent();
        }

        isDonationSent = true;

        uint256 donationAmount = Math.mulDiv(totalSupply(), DONATION_FACTOR, 1e18);
        _mint(donationBeneficiary, donationAmount);
        emit Donation(donationBeneficiary, donationAmount);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
