// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {ERC20} that allows token deployers to set a tax on transfers from and to specific addresses.
 */
abstract contract ERC20TaxableUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /// @notice Emitted when an exchange pool address is added to the set of tracked pool addresses.
    event ExchangePoolAdded(address exchangePool);

    /// @notice Emitted when an exchange pool address is removed from the set of tracked pool addresses.
    event ExchangePoolRemoved(address exchangePool);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev The set of addresses exempt from tax.
    EnumerableSet.AddressSet internal _exempted;

    /// @dev Set of exchange pool addresses.
    EnumerableSet.AddressSet internal _exchangePools;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice Receiver of the tax (set to owner)
    address public taxBeneficiary;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /**
     * @notice Get list of addresses designated as exchange pools.
     * @return An array of exchange pool addresses.
     */
    function getExchangePoolAddresses() external view returns (address[] memory) {
        return _exchangePools.values();
    }

    /**
     * @notice Get number of tokens to pay as tax.
     * @dev There is no easy way to differentiate between a user selling tokens and a user adding liquidity to the pool.
     * In both cases tokens are transferred to the pool. This is an unfortunate case where users have to accept being
     * taxed on liquidity additions. To get around this issue, a separate liquidity addition contract can be deployed.
     * This contract can be exempt from taxes if its functionality is verified to only add liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(address benefactor, address beneficiary, uint256 amount) public view returns (uint256) {
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        return (amount * taxBasisPoints) / 10_000;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Add an address to the set of exchange pool addresses.
     * @dev Nothing happens if the pool already exists in the set.
     * @param exchangePool Address of exchange pool to add.
     */
    function addExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.add(exchangePool)) {
            emit ExchangePoolAdded(exchangePool);
        }
    }

    /**
     * @notice Add address to set of tax-exempted addresses.
     * @param exemption Address to add to set of tax-exempted addresses.
     */
    function addExemption(address exemption) external onlyOwner {
        if (_exempted.add(exemption)) {
            emit TaxExemptionUpdated(exemption, true);
        }
    }

    /**
     * @notice Remove an address from the set of exchange pool addresses.
     * @dev Nothing happens if the pool doesn't exist in the set.
     * @param exchangePool Address of exchange pool to remove.
     */
    function removeExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.remove(exchangePool)) {
            emit ExchangePoolRemoved(exchangePool);
        }
    }

    /**
     * @notice Remove address from set of tax-exempted addresses.
     * @param exemption Address to remove from set of tax-exempted addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        if (_exempted.remove(exemption)) {
            emit TaxExemptionUpdated(exemption, false);
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Initialize the contract with calls to parent initializers.
    function __ERC20Taxable_init(
        address owner,
        address exchangePool,
        uint256 initialTaxBasisPoints
    )
        internal
        onlyInitializing
    {
        __Ownable_init_unchained(owner);
        __ERC20Taxable_init_unchained(owner, exchangePool, initialTaxBasisPoints);
    }

    /// @dev Initialize the contract without calling parent initializers.
    function __ERC20Taxable_init_unchained(
        address owner,
        address exchangePool,
        uint256 initialTaxBasisPoints
    )
        internal
        onlyInitializing
    {
        taxBeneficiary = address(1);
        _exempted.add(owner);
        emit TaxExemptionUpdated(owner, true);
        _exchangePools.add(exchangePool);
        emit ExchangePoolAdded(exchangePool);
        taxBasisPoints = initialTaxBasisPoints;
    }

    /// @dev See {ERC20-_update}.
    function _update(address from, address to, uint256 value) internal virtual override {
        // TODO: make `getTax` internal.
        uint256 tax = getTax(from, to, value);
        uint256 taxedAmount = value - tax;
        super._update(from, to, taxedAmount);
        if (tax > 0) {
            // TODO: make `taxBeneficiary` immutable if possible.
            super._update(from, taxBeneficiary, tax);
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
