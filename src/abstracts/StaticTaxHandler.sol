pragma solidity >=0.8.25;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";




/**
 * @title Exchange pool processor abstract contract.
 * @notice Keeps an enumerable set of designated exchange addresses as well as a single primary pool address.
 */
abstract contract ExchangePoolProcessor is Initializable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Set of exchange pool addresses.
    EnumerableSet.AddressSet internal _exchangePools;


    /// @notice Emitted when an exchange pool address is added to the set of tracked pool addresses.
    event ExchangePoolAdded(address exchangePool);

    /// @notice Emitted when an exchange pool address is removed from the set of tracked pool addresses.
    event ExchangePoolRemoved(address exchangePool);

    function __ExchangePoolProcessor_init(address owner, address exchangePool) internal onlyInitializing {
        __Ownable_init(owner);
        _exchangePools.add(exchangePool);
        emit ExchangePoolAdded(exchangePool);
    }

    /**
     * @notice Get list of addresses designated as exchange pools.
     * @return An array of exchange pool addresses.
     */
    function getExchangePoolAddresses() external view returns (address[] memory) {
        return _exchangePools.values();
    }

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
     * @notice Remove an address from the set of exchange pool addresses.
     * @dev Nothing happens if the pool doesn't exist in the set.
     * @param exchangePool Address of exchange pool to remove.
     */
    function removeExchangePool(address exchangePool) external onlyOwner {
        if (_exchangePools.remove(exchangePool)) {
            emit ExchangePoolRemoved(exchangePool);
        }
    }
}


/**
 * @title Static Tax Handler
 * @notice Charges taxBasisPoints on all Buys/Sells
 */
abstract contract StaticTaxHandler is Initializable, ExchangePoolProcessor {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The set of addresses exempt from tax.
    EnumerableSet.AddressSet private _exempted;
    /// @notice Receiver of the tax (set to owner)
    address public taxBeneficiary;
    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);



    function __StaticTaxHandler_init(bytes calldata data) internal onlyInitializing {
        // Don't like the fact that owner is passed in calldata, it should be propogated via msg.sender...
        (uint256 initialTaxBasisPoints, address owner, address exchangePool) =  abi.decode(data,(uint256,address,address));
        __ExchangePoolProcessor_init(owner, exchangePool);
        taxBasisPoints = initialTaxBasisPoints;
        _exempted.add(owner);
        taxBeneficiary = owner;
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
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) public view  returns (uint256) {
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        return (amount * taxBasisPoints) / 10000;
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
     * @notice Remove address from set of tax-exempted addresses.
     * @param exemption Address to remove from set of tax-exempted addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        if (_exempted.remove(exemption)) {
            emit TaxExemptionUpdated(exemption, false);
        }
    }
}
