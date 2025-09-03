// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { LibAsset } from "../shared/libraries/LibAsset.sol";
import { LibPermit } from "../shared/libraries/LibPermit.sol";

import { IDZapZapCore } from "../interfaces/IDZapZapCore.sol";
import { PermitBatchTransferFrom } from "../interfaces/IPermit2.sol";

import { DZapCoreBase } from "./DZapCoreBase.sol";
import { DZapExecution } from "./DZapExecution.sol";

import { FeeConfig, ZapData, InputErc20Tokens, TokenInfo } from "./Types.sol";
import { DustReceiverIsZeroAddress, IntegratorIsZeroAddress } from "./Errors.sol";

/*  
---------------------------------------------------------
---------------------------------------------------------

 /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$ 
| $$__  $$|_____ $$  /$$__  $$| $$__  $$
| $$  \ $$     /$$/ | $$  \ $$| $$  \ $$
| $$  | $$    /$$/  | $$$$$$$$| $$$$$$$/
| $$  | $$   /$$/   | $$__  $$| $$____/ 
| $$  | $$  /$$/    | $$  | $$| $$      
| $$$$$$$/ /$$$$$$$$| $$  | $$| $$      
|_______/ |________/|__/  |__/|__/       


Author: DZap <https://dzap.io> (https://x.com/dzap_io)

---------------------------------------------------------
---------------------------------------------------------
*/

/// @title DZapZapCore
/// @notice Main contract for executing zap transactions across protocols
/// @dev Inherits from modular abstract contracts for clean separation of concerns
contract DZapZapCore is ReentrancyGuard, DZapExecution, IDZapZapCore {
    // ============= CONSTRUCTOR =============

    /// @param _owner Owner of the contract
    /// @param _protocolFeeVault Address where protocol fees are sent
    /// @param _zapVerifier Address of the zap verifier
    /// @param _permit2 Address of the permit2 contract
    /// @param _uniswapPermit2 Address of the uniswap permit2 contract
    /// @param _uniswapPermit2BytecodeHash Hash of the uniswap permit2 bytecode
    /// @param _salt Random salt for contract creation
    constructor(
        address _owner,
        address _protocolFeeVault,
        address _zapVerifier,
        address _permit2,
        address _uniswapPermit2,
        bytes32 _uniswapPermit2BytecodeHash,
        bytes32 _salt
    ) DZapCoreBase(_owner, _protocolFeeVault, _zapVerifier, _permit2, _uniswapPermit2, _uniswapPermit2BytecodeHash, _salt) {}

    // ============= EXTERNAL FUNCTIONS =============

    /// @inheritdoc IDZapZapCore
    function zap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        uint256 _deadline,
        address _dustReceiver,
        InputErc20Tokens[] calldata _inputTokens,
        FeeConfig calldata _feeConfig,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable nonReentrant whenNotPaused refundExcessNative(_dustReceiver) {
        require(_dustReceiver != address(0), DustReceiverIsZeroAddress());
        require(_feeConfig.integrator != address(0), IntegratorIsZeroAddress());

        bytes32 zapDataHash = keccak256(abi.encode(_zapData));
        bytes32 feeDataHash = keccak256(abi.encode(_feeConfig));

        _handleZapVerification(_transactionId, zapDataHash, feeDataHash, msg.sender, _deadline, _zapVerificationSignature);

        LibAsset.depositBatch(permit2, msg.sender, _inputTokens);

        _handleZap(_zapData, msg.sender);

        _processFee(_feeConfig);

        _handleSweepTokens(_sweepDust, _dustReceiver);

        emit Zapped(_transactionId, msg.sender, _feeConfig.integrator, _crosschainData);
    }

    /// @inheritdoc IDZapZapCore
    function zapWithBatchDeposit(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _batchDepositSignature,
        uint256 _deadline,
        address _dustReceiver,
        PermitBatchTransferFrom calldata _tokenDepositDetails,
        FeeConfig calldata _feeConfig,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable nonReentrant whenNotPaused refundExcessNative(_dustReceiver) {
        require(_dustReceiver != address(0), DustReceiverIsZeroAddress());
        require(_feeConfig.integrator != address(0), IntegratorIsZeroAddress());

        bytes32 zapDataHash = keccak256(abi.encode(_zapData));
        bytes32 feeDataHash = keccak256(abi.encode(_feeConfig));

        _handleZapVerification(_transactionId, zapDataHash, feeDataHash, msg.sender, _deadline, _zapVerificationSignature);

        LibAsset.depositBatch(permit2, msg.sender, _tokenDepositDetails, _batchDepositSignature);

        _handleZap(_zapData, msg.sender);

        _processFee(_feeConfig);

        _handleSweepTokens(_sweepDust, _dustReceiver);

        emit Zapped(_transactionId, msg.sender, _feeConfig.integrator, _crosschainData);
    }

    /// @inheritdoc IDZapZapCore
    function executeZap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _userIntentSignature,
        uint256 _zapDeadline,
        uint256 _userIntentDeadline,
        address _user,
        address _dustReceiver,
        InputErc20Tokens[] calldata _inputTokens,
        FeeConfig calldata _feeConfig,
        TokenInfo[] calldata _executorFeeInfo,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable nonReentrant whenNotPaused refundExcessNative(_dustReceiver) {
        require(_dustReceiver != address(0), DustReceiverIsZeroAddress());
        require(_feeConfig.integrator != address(0), IntegratorIsZeroAddress());

        bytes32 zapDataHash = keccak256(abi.encode(_zapData));
        bytes32 feeDataHash = keccak256(abi.encode(_feeConfig));

        _handleZapVerification(_transactionId, zapDataHash, feeDataHash, _user, _zapDeadline, _zapVerificationSignature);

        _handleGaslessVerification(
            _transactionId,
            zapDataHash,
            feeDataHash,
            keccak256(abi.encode(_executorFeeInfo)),
            keccak256(_crosschainData),
            keccak256(abi.encode(_sweepDust)),
            _user,
            _dustReceiver,
            _userIntentDeadline,
            _userIntentSignature
        );

        LibAsset.depositBatch(permit2, _user, _inputTokens);

        _handleZap(_zapData, _user);

        _processFee(_feeConfig);

        _transferExecutorFees(_executorFeeInfo);

        _handleSweepTokens(_sweepDust, _dustReceiver);

        emit GaslessZapped(_transactionId, msg.sender, _user, _feeConfig.integrator, _crosschainData);
    }

    /// @inheritdoc IDZapZapCore
    function executeZapWithWitness(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _userIntentSignature,
        uint256 _zapDeadline,
        address _user,
        address _dustReceiver,
        PermitBatchTransferFrom calldata _tokenDepositDetails,
        FeeConfig calldata _feeConfig,
        TokenInfo[] calldata _executorFeeInfo,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable nonReentrant whenNotPaused refundExcessNative(_dustReceiver) {
        require(_dustReceiver != address(0), DustReceiverIsZeroAddress());
        require(_feeConfig.integrator != address(0), IntegratorIsZeroAddress());

        bytes32 zapDataHash = keccak256(abi.encode(_zapData));
        bytes32 feeDataHash = keccak256(abi.encode(_feeConfig));

        _handleZapVerification(_transactionId, zapDataHash, feeDataHash, _user, _zapDeadline, _zapVerificationSignature);

        bytes32 witness = keccak256(
            abi.encode(
                _GASLESS_WITNESS_TYPEHASH,
                _transactionId,
                _user,
                _dustReceiver,
                zapDataHash,
                feeDataHash,
                keccak256(abi.encode(_executorFeeInfo)),
                keccak256(_crosschainData),
                keccak256(abi.encode(_sweepDust))
            )
        );

        LibPermit.permit2BatchWitnessTransferFrom(
            permit2,
            _user,
            address(this),
            witness,
            _tokenDepositDetails,
            _userIntentSignature,
            _GASLESS_WITNESS_TYPE_STRING
        );

        _handleZap(_zapData, _user);

        _processFee(_feeConfig);

        _transferExecutorFees(_executorFeeInfo);

        _handleSweepTokens(_sweepDust, _dustReceiver);

        emit GaslessZapped(_transactionId, msg.sender, _user, _feeConfig.integrator, _crosschainData);
    }
}
