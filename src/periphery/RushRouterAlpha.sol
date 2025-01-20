// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";
import { IWETH } from "src/external/IWETH.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { IFeeCalculator } from "src/interfaces/IFeeCalculator.sol";
import { RL, FC } from "src/types/DataTypes.sol";

/**
 * @title RushRouterAlpha
 * @notice A periphery contract that acts as a router for Rush protocol operations with gated access to RushLauncher
 * functions.
 */
contract RushRouterAlpha is Nonces {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    /// @dev The RushERC20Basic kind (i.e., keccak256("RushERC20Basic")).
    bytes32 internal constant RUSH_ERC20_BASIC_KIND = 0xcac1368504ad87313cdd2f6dcf30ca9b9464d5bcb5a8a0613bbe9dce5b33a365;

    /// @dev The RushERC20Taxable kind (i.e., keccak256("RushERC20Taxable")).
    bytes32 internal constant RUSH_ERC20_TAXABLE_KIND =
        0xfa3f84d263ed55bc45f8e22cdb3a7481292f68ee28ab539b69876f8dc1535b40;

    /// @dev The RushERC20Donatable kind (i.e., keccak256("RushERC20Donatable")).
    bytes32 internal constant RUSH_ERC20_DONATABLE_KIND =
        0xf3276aaa36076beebbabfe73c27d58e731e1c37a0f9ab8753064868d7dbdf469;

    /// @dev The maximum supply of a RushERC20 token.
    uint256 internal constant MAX_SUPPLY = 1_000_000_000e18;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ ENUMS +|=------------------------------------- //

    /// @dev Enum of Rush token types currently supported.
    enum ERC20Type {
        Basic,
        Taxable,
        Donatable
    }

    /// @dev Enum of gas modes supported for launching ERC20 tokens.
    enum GasMode {
        Default,
        Sponsored
    }

    /// @dev The tax tier of a taxable ERC20 token.
    enum TaxTier {
        Small,
        Medium,
        Large
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ ERRORS +|=------------------------------------ //

    /// @dev Thrown when the signature is invalid.
    error RushRouterAlpha_InvalidSignature();

    /// @dev Thrown when the minimum shares out is not met.
    error RushRouterAlpha_MinSharesError();

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @notice The address of the LiquidityDeployer contract.
    ILiquidityDeployer public immutable LIQUIDITY_DEPLOYER;

    /// @notice The address of the LiquidityPool contract.
    ILiquidityPool public immutable LIQUIDITY_POOL;

    /// @notice The address of the RushLauncher contract.
    IRushLauncher public immutable RUSH_LAUNCHER;

    /// @notice The fee sponsor address.
    address public immutable SPONSOR_ADDRESS;

    /// @notice The ECDSA verifier address.
    address public immutable VERIFIER_ADDRESS;

    /// @notice The WETH address.
    address public immutable WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param rushLauncher_ The address of the RushLauncher contract.
     * @param sponsorAddress_ The fee sponsor address.
     * @param verifierAddress_ The ECDSA verifier address.
     */
    constructor(IRushLauncher rushLauncher_, address sponsorAddress_, address verifierAddress_) {
        RUSH_LAUNCHER = rushLauncher_;
        SPONSOR_ADDRESS = sponsorAddress_;
        VERIFIER_ADDRESS = verifierAddress_;
        LIQUIDITY_DEPLOYER = ILiquidityDeployer(rushLauncher_.LIQUIDITY_DEPLOYER());
        LIQUIDITY_POOL = ILiquidityPool(LIQUIDITY_DEPLOYER.LIQUIDITY_POOL());
        WETH = LIQUIDITY_DEPLOYER.WETH();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ FALLBACK FUNCTIONS +|=------------------------------ //

    receive() external payable {
        // Only accept ETH via fallback from the WETH contract.
        assert(msg.sender == WETH);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Launch an ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     * @param signature The ECDSA signature of the launch parameters.
     */
    function launchERC20(
        string calldata name,
        string calldata symbol,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 maxTotalFee,
        bytes calldata signature
    )
        external
        payable
    {
        // Launch the ERC20 token.
        _launchERC20({
            name: name,
            symbol: symbol,
            liquidityAmount: liquidityAmount,
            liquidityDuration: liquidityDuration,
            liquidityMsgValue: msg.value,
            maxTotalFee: maxTotalFee,
            gasMode: GasMode.Default,
            signature: signature
        });
    }

    /**
     * @notice Launch an ERC20 token with a sponsored liquidity deployment and minimum deployment parameters.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     * @param signature The ECDSA signature of the launch parameters.
     */
    function launchERC20Sponsored(
        string calldata name,
        string calldata symbol,
        uint256 maxTotalFee,
        bytes calldata signature
    )
        external
        payable
    {
        // Launch the ERC20 token with a sponsored liquidity deployment.
        uint256 liquidityAmount = LIQUIDITY_DEPLOYER.MIN_DEPLOYMENT_AMOUNT();
        uint256 liquidityDuration = LIQUIDITY_DEPLOYER.MIN_DURATION();
        _launchERC20({
            name: name,
            symbol: symbol,
            liquidityAmount: liquidityAmount,
            liquidityDuration: liquidityDuration,
            liquidityMsgValue: 
            // Deployment fee is sourced from the sponsor.
            _sponsorLiquidityFee({ liquidityAmount: liquidityAmount, liquidityDuration: liquidityDuration })
            // Additional msg.value is swapped to RushERC20
            + msg.value,
            maxTotalFee: maxTotalFee,
            gasMode: GasMode.Sponsored,
            signature: signature
        });
    }

    /**
     * @notice Launch a taxable ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param taxTier The tax tier of the launched ERC20 token.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     * @param signature The ECDSA signature of the launch parameters.
     */
    function launchERC20Taxable(
        string calldata name,
        string calldata symbol,
        TaxTier taxTier,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 maxTotalFee,
        bytes calldata signature
    )
        external
        payable
    {
        {
            // Check the ECDSA signature is valid.
            _checkSignature({
                message: abi.encodePacked(
                    msg.sender,
                    _useNonce(msg.sender),
                    address(this),
                    taxTier,
                    liquidityAmount,
                    liquidityDuration,
                    ERC20Type.Taxable
                ),
                signature: signature
            });
        }

        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: msg.value }(
            RL.LaunchParams({
                originator: msg.sender,
                kind: RUSH_ERC20_TAXABLE_KIND,
                name: name,
                symbol: symbol,
                maxSupply: MAX_SUPPLY,
                data: abi.encode(
                    msg.sender,
                    address(LIQUIDITY_DEPLOYER),
                    taxTier == TaxTier.Small ? 100 : taxTier == TaxTier.Medium ? 300 : 500
                ),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: maxTotalFee
            })
        );
    }

    /**
     * @notice Launch a donatable ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param donationBeneficiary The address of the donation beneficiary.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     * @param signature The ECDSA signature of the launch parameters.
     */
    function launchERC20Donatable(
        string calldata name,
        string calldata symbol,
        address donationBeneficiary,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 maxTotalFee,
        bytes calldata signature
    )
        external
        payable
    {
        {
            // Check the ECDSA signature is valid.
            _checkSignature({
                message: abi.encodePacked(
                    msg.sender,
                    _useNonce(msg.sender),
                    address(this),
                    liquidityAmount,
                    liquidityDuration,
                    ERC20Type.Donatable,
                    donationBeneficiary
                ),
                signature: signature
            });
        }

        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: msg.value }(
            RL.LaunchParams({
                originator: msg.sender,
                kind: RUSH_ERC20_DONATABLE_KIND,
                name: name,
                symbol: symbol,
                maxSupply: MAX_SUPPLY,
                data: abi.encode(donationBeneficiary, address(LIQUIDITY_DEPLOYER)),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: maxTotalFee
            })
        );
    }

    /**
     * @notice Lend WETH to the LiquidityPool.
     * @param amount The amount of WETH to lend.
     */
    function lend(uint256 amount, uint256 minSharesOut) external returns (uint256 sharesOut) {
        // Transfer the amount of WETH to this contract.
        IERC20(WETH).transferFrom({ from: msg.sender, to: address(this), value: amount });

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: amount });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        if ((sharesOut = LIQUIDITY_POOL.deposit({ assets: amount, receiver: msg.sender })) < minSharesOut) {
            revert RushRouterAlpha_MinSharesError();
        }
    }

    /**
     * @notice Lend ETH to the LiquidityPool.
     */
    function lendETH(uint256 minSharesOut) external payable returns (uint256 sharesOut) {
        // Deposit the ETH into WETH.
        IWETH(WETH).deposit{ value: msg.value }();

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: msg.value });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        if ((sharesOut = LIQUIDITY_POOL.deposit({ assets: msg.value, receiver: msg.sender })) < minSharesOut) {
            revert RushRouterAlpha_MinSharesError();
        }
    }

    /**
     * @notice Withdraw lent WETH from the LiquidityPool.
     * @param amount The amount of WETH to withdraw.
     */
    function withdraw(uint256 amount) external {
        // Calculate the amount of shares to redeem.
        uint256 shares = LIQUIDITY_POOL.previewWithdraw(amount);

        // Transfer the amount of shares to this contract.
        IERC20(LIQUIDITY_POOL).transferFrom({ from: msg.sender, to: address(this), value: shares });

        // Redeem the amount of shares from the LiquidityPool and transfer the corresponding amount of WETH to the
        // sender.
        LIQUIDITY_POOL.redeem({ shares: shares, receiver: msg.sender, owner: address(this) });
    }

    /**
     * @notice Withdraw lent ETH from the LiquidityPool.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external {
        // Calculate the amount of shares to redeem.
        uint256 shares = LIQUIDITY_POOL.previewWithdraw(amount);

        // Transfer the amount of shares to this contract.
        IERC20(LIQUIDITY_POOL).transferFrom({ from: msg.sender, to: address(this), value: shares });

        // Redeem the amount of shares from the LiquidityPool and transfer the corresponding amount of WETH to this
        // contract.
        uint256 received = LIQUIDITY_POOL.redeem({ shares: shares, receiver: address(this), owner: address(this) });

        // Withdraw the received WETH to ETH.
        IWETH(WETH).withdraw(received);

        // Transfer the amount of WETH to the sender.
        payable(msg.sender).transfer(received);
    }

    /**
     * @notice Unwind deployed liquidity after the liquidity duration has expired.
     * @param uniV2Pair The address of the Uniswap V2 pair to unwind.
     */
    function unwindLiquidity(address uniV2Pair) external {
        // Unwind the liquidity deployment.
        LIQUIDITY_DEPLOYER.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

    /// @dev Check the ECDSA signature is valid.
    function _checkSignature(bytes memory message, bytes memory signature) internal view {
        bytes32 signedMessageHash = keccak256(message).toEthSignedMessageHash();
        if (signedMessageHash.recover(signature) != VERIFIER_ADDRESS) {
            revert RushRouterAlpha_InvalidSignature();
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------=|+ INTERNAL NON-CONSTANT FUNCTIONS +|=------------------------ //

    /// @dev Launch an ERC20 token.
    function _launchERC20(
        string calldata name,
        string calldata symbol,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 liquidityMsgValue,
        uint256 maxTotalFee,
        GasMode gasMode,
        bytes calldata signature
    )
        internal
    {
        // Check the ECDSA signature is valid.
        _checkSignature({
            message: abi.encodePacked(
                msg.sender,
                _useNonce(msg.sender),
                address(this),
                liquidityAmount,
                liquidityDuration,
                ERC20Type.Basic,
                gasMode
            ),
            signature: signature
        });

        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: liquidityMsgValue }(
            RL.LaunchParams({
                originator: msg.sender,
                kind: RUSH_ERC20_BASIC_KIND,
                name: name,
                symbol: symbol,
                maxSupply: MAX_SUPPLY,
                data: "",
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: maxTotalFee
            })
        );
    }

    /**
     * @dev Sponsor the liquidity deployment fee.
     *
     * Requirements:
     * - The sponsor address must have approved the contract to spend the fee amount.
     *
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    function _sponsorLiquidityFee(
        uint256 liquidityAmount,
        uint256 liquidityDuration
    )
        internal
        returns (uint256 feeAmount)
    {
        (feeAmount,) = IFeeCalculator(LIQUIDITY_DEPLOYER.feeCalculator()).calculateFee(
            FC.CalculateFeeParams({
                duration: liquidityDuration,
                newLiquidity: liquidityAmount,
                outstandingLiquidity: LIQUIDITY_POOL.outstandingAssets(),
                reserveFactor: LIQUIDITY_DEPLOYER.RESERVE_FACTOR(),
                totalLiquidity: LIQUIDITY_POOL.lastSnapshotTotalAssets()
            })
        );
        // Transfer the fee amount from the sponsor to this contract.
        IERC20(WETH).transferFrom({ from: SPONSOR_ADDRESS, to: address(this), value: feeAmount });
        // Convert the fee amount to ETH.
        IWETH(WETH).withdraw(feeAmount);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}
