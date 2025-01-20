// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {ERC20} that adds a tax to transfers to and from specific addresses.
 */
abstract contract ERC20TaxableUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when an exchange pool address is added to the set of tracked pool addresses.
     * @param exchangePool Address of the exchange pool added.
     */
    event ExchangePoolAdded(address indexed exchangePool);

    /**
     * @notice Emitted when an exchange pool address is removed from the set of tracked pool addresses.
     * @param exchangePool Address of the exchange pool removed.
     */
    event ExchangePoolRemoved(address indexed exchangePool);

    /**
     * @notice Emitted when an address is added to the set of tax-exempt addresses.
     * @param exemption Address of the tax-exempt address added.
     */
    event ExemptionAdded(address indexed exemption);

    /**
     * @notice Emitted when an address is removed from the set of tax-exempt addresses.
     * @param exemption Address of the tax-exempt address removed.
     */
    event ExemptionRemoved(address indexed exemption);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev Set of exchange pool addresses.
    EnumerableSet.AddressSet internal _exchangePools;

    /// @dev Set of addresses exempt from tax.
    EnumerableSet.AddressSet internal _exempted;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice How much tax to collect in basis points. 10,000 bps = 100% tax.
    uint96 public taxBasisPoints;

    /// @notice Receiver of the tax.
    address public taxBeneficiary;

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
     * @notice Get list of addresses designated as tax-exempt.
     * @return An array of tax-exempt addresses.
     */
    function getExemptedAddresses() external view returns (address[] memory) {
        return _exempted.values();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Add an address to the set of exchange pool addresses.
     * @dev Nothing happens if the pool already exists in the set.
     * @param exchangePool Address to add to set of exchange pool addresses.
     */
    function addExchangePool(address exchangePool) external onlyOwner {
        _addExchangePool(exchangePool);
    }

    /**
     * @notice Add address to set of tax-exempt addresses.
     * @dev Nothing happens if the address is already in the set.
     * @param exemption Address to add to set of tax-exempt addresses.
     */
    function addExemption(address exemption) external onlyOwner {
        _addExemption(exemption);
    }

    /**
     * @notice Remove an address from the set of exchange pool addresses.
     * @dev Nothing happens if the pool doesn't exist in the set.
     * @param exchangePool Address to remove from set of exchange pool addresses.
     */
    function removeExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.remove(exchangePool)) {
            emit ExchangePoolRemoved(exchangePool);
        }
    }

    /**
     * @notice Remove address from set of tax-exempt addresses.
     * @dev Nothing happens if the address is not in the set.
     * @param exemption Address to remove from set of tax-exempt addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        _removeExemption(exemption);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

    /**
     * @dev Get number of tokens to pay as tax.
     * @dev There is no easy way to differentiate between a user selling tokens and a user adding liquidity to the pool.
     * In both cases tokens are transferred to the pool. This is an unfortunate case where users have to accept being
     * taxed on liquidity additions. To avoid this issue, a separate liquidity addition contract can be deployed and
     * exempted from taxes if its functionality is verified to only add liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function _getTax(address benefactor, address beneficiary, uint256 amount) internal view returns (uint256) {
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

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Initialize the contract with calls to parent initializers.
    function __ERC20Taxable_init(
        address initialOwner,
        address initialExchangePool,
        address initialExemption,
        uint96 initialTaxBasisPoints
    )
        internal
        onlyInitializing
    {
        __Ownable_init_unchained(initialOwner);
        __ERC20Taxable_init_unchained({
            initialExchangePool: initialExchangePool,
            initialExemption: initialExemption,
            initialTaxBasisPoints: initialTaxBasisPoints
        });
    }

    /// @dev Initialize the contract without calling parent initializers.
    function __ERC20Taxable_init_unchained(
        address initialExchangePool,
        address initialExemption,
        uint96 initialTaxBasisPoints
    )
        internal
        onlyInitializing
    {
        _addExchangePool(initialExchangePool);
        _addExemption(initialExemption);
        taxBasisPoints = initialTaxBasisPoints;
    }

    /// @dev Add an address to the set of exchange pool addresses.
    function _addExchangePool(address exchangePool) internal {
        if (_exchangePools.add(exchangePool)) {
            emit ExchangePoolAdded(exchangePool);
        }
    }

    /// @dev Add address to set of tax-exempt addresses.
    function _addExemption(address exemption) internal {
        if (_exempted.add(exemption)) {
            emit ExemptionAdded(exemption);
        }
    }

    /// @dev Remove an address from the set of tax-exempt addresses.
    function _removeExemption(address exemption) internal {
        if (_exempted.remove(exemption)) {
            emit ExemptionRemoved(exemption);
        }
    }

    /// @dev See {OwnableUpgradeable-_transferOwnership}.
    function _transferOwnership(address newOwner) internal virtual override {
        taxBeneficiary = newOwner;
        _addExemption(newOwner);
        _removeExemption(owner());
        super._transferOwnership(newOwner);
    }

    /// @dev See {ERC20-_update}.
    function _update(address from, address to, uint256 value) internal virtual override {
        uint256 tax = _getTax(from, to, value);
        super._update(from, to, value - tax);
        if (tax > 0) {
            super._update(from, taxBeneficiary, tax);
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
