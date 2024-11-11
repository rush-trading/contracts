// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ILiquidityDeployer} from "src/interfaces/ILiquidityDeployer.sol";
import { LD } from "src/types/DataTypes.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


/**
 * @dev Extension of {ERC20} that includes a donation to a given, well known address.
 */
abstract contract ERC20DonatableUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;



    /// @notice raise when token has not yet been around. In order to maintain invariant, donation only available
    /// after
    error ERC20Donatable_NotUnwoundYet();

    /// @notice token has been unowund but we did not meet the threshold
    error ERC20Donatable_UnwindThresholdNotMet();

    error ERC20Donatable_DonationAlreadySent();


    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    event Donation(address indexed receiver, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice Reciever of the donation
    address public donationBeneficiary;

    /// @notice UniV2 Pool address TODO: can change to use create2 to derive
    address uniPool;

    uint256 public constant FIXED_DONATION_AMOUNT = 10000000e18;
    /// @notice Liquidity Deployer, the only address allowed to call donate
    ILiquidityDeployer public liquidityDeployer;

    bool public isDonationSent = false;


    // #endregion ----------------------------------------------------------------------------------- //



    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Initialize the contract with calls to parent initializers.

    function __ERC20Donatable_init(
        address _donationBeneficiary,
        address _liquidityDeployer,
        address _uniPool
    ) internal
      onlyInitializing {

        __ERC20Donatable_init_unchained(_donationBeneficiary, _liquidityDeployer, _uniPool);

    }





    /// @dev Initialize the contract without calling parent initializers.
    function __ERC20Donatable_init_unchained(
        address _donationBeneficiary,
        address _liquidityDeployer,
        address _uniPool
    )
        internal
        onlyInitializing
    {
        donationBeneficiary = _donationBeneficiary;
        liquidityDeployer = ILiquidityDeployer(_liquidityDeployer);
        uniPool = _uniPool;
    }


    // #endregion ----------------------------------------------------------------------------------- //


    // #region -----------------------=|+ PUBLIC  FUNCTIONS +|=------------------------ //
    function donate() public {
        LD.LiquidityDeployment memory liqDeployment = liquidityDeployer.getLiquidityDeployment(uniPool);
        if (!liqDeployment.isUnwound) {
            revert ERC20Donatable_NotUnwoundYet();
        }

        if (!liqDeployment.isUnwindThresholdMet) {
            revert ERC20Donatable_UnwindThresholdNotMet();
        }

        if (isDonationSent) {
            revert ERC20Donatable_DonationAlreadySent();
        }

        _mint(donationBeneficiary, FIXED_DONATION_AMOUNT);
        isDonationSent = true;

        emit Donation(donationBeneficiary, FIXED_DONATION_AMOUNT);

    }

}
