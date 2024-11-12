// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { LD } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @dev Extension of {ERC20} that includes a donation to a given address.
 */
abstract contract ERC20DonatableUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when a donation is sent.
     * @param receiver Address of the donation receiver.
     * @param amount Amount of the donation.
     */
    event DonationSent(address indexed receiver, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice Reciever of the donation.
    address public donationBeneficiary;

    /// @notice Flag to check if donation has been sent.
    bool public isDonationSent;

    /// @notice Amount of the donation.
    uint256 public donationAmount;

    /// @notice Address of the liquidity deployer.
    ILiquidityDeployer public liquidityDeployer;

    /// @notice Address of the Uniswap V2 pair for the token.
    address public uniV2Pair;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Initialize the contract with calls to parent initializers.
    function __ERC20Donatable_init(
        address _donationBeneficiary,
        uint256 _donationAmount,
        address _liquidityDeployer,
        address _uniV2Pair
    )
        internal
        onlyInitializing
    {
        __ERC20Donatable_init_unchained(_donationBeneficiary, _donationAmount, _liquidityDeployer, _uniV2Pair);
    }

    /// @dev Initialize the contract without calling parent initializers.
    function __ERC20Donatable_init_unchained(
        address _donationBeneficiary,
        uint256 _donationAmount,
        address _liquidityDeployer,
        address _uniV2Pair
    )
        internal
        onlyInitializing
    {
        donationBeneficiary = _donationBeneficiary;
        donationAmount = _donationAmount;
        liquidityDeployer = ILiquidityDeployer(_liquidityDeployer);
        uniV2Pair = _uniV2Pair;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    function donate() external {
        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        if (!liquidityDeployment.isUnwound) {
            revert Errors.ERC20DonatableUpgradeable_PairNotUnwound();
        }
        if (!liquidityDeployment.isUnwindThresholdMet) {
            revert Errors.ERC20DonatableUpgradeable_UnwindThresholdNotMet();
        }
        if (isDonationSent) {
            revert Errors.ERC20DonatableUpgradeable_DonationAlreadySent();
        }

        isDonationSent = true;

        _mint(donationBeneficiary, donationAmount);
        emit DonationSent(donationBeneficiary, donationAmount);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
