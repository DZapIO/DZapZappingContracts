// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { DZapCoreBase } from "./DZapCoreBase.sol";
import { UnauthorizedSigner, SigDeadlineExpired } from "./Errors.sol";

/// @title DZapVerification
/// @author DZap
/// @notice Abstract contract handling all signature verification logic
/// @dev Implements EIP-712 signature verification for zap operations
abstract contract DZapVerification is DZapCoreBase {
    // ============= INTERNAL VERIFICATION FUNCTIONS =============

    /// @notice Verifies EIP-712 signature against expected signer
    /// @param _verifier Expected signer address
    /// @param _msgHash Message hash to verify
    /// @param _signature Signature to verify
    function _verifySignature(address _verifier, bytes32 _msgHash, bytes calldata _signature) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, _msgHash));
        if (ECDSA.recover(digest, _signature) != _verifier) {
            revert UnauthorizedSigner();
        }
    }

    /// @notice Handles zap verification with signature validation
    /// @param _transactionId Unique transaction identifier
    /// @param _zapDataHash Hash of zap execution data
    /// @param _feeDataHash Hash of fee configuration
    /// @param _user User address for nonce tracking
    /// @param _deadline Signature expiration timestamp
    /// @param _signature Verifier signature
    function _handleZapVerification(
        bytes32 _transactionId,
        bytes32 _zapDataHash,
        bytes32 _feeDataHash,
        address _user,
        uint256 _deadline,
        bytes calldata _signature
    ) internal {
        if (_deadline < block.timestamp) revert SigDeadlineExpired();

        bytes32 msgHash = keccak256(
            abi.encode(_SIGNED_ZAP_DATA_TYPEHASH, _transactionId, _user, nonce[_user], _deadline, _zapDataHash, _feeDataHash)
        );

        _verifySignature(zapVerifier, msgHash, _signature);

        unchecked {
            ++nonce[_user];
        }
    }

    /// @notice Handles gasless verification with user intent signature
    /// @param _transactionId Unique transaction identifier
    /// @param _zapDataHash Hash of zap execution data
    /// @param _feeDataHash Hash of fee configuration
    /// @param _executorFeeDataHash Hash of executor fee data
    /// @param _crosschainDataHash Hash of crosschain data
    /// @param _sweepDustHash Hash of sweep dust data
    /// @param _user User address for nonce tracking
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _deadline Signature expiration timestamp
    /// @param _userIntentSignature User's intent signature
    function _handleGaslessVerification(
        bytes32 _transactionId,
        bytes32 _zapDataHash,
        bytes32 _feeDataHash,
        bytes32 _executorFeeDataHash,
        bytes32 _crosschainDataHash,
        bytes32 _sweepDustHash,
        address _user,
        address _dustReceiver,
        uint256 _deadline,
        bytes calldata _userIntentSignature
    ) internal {
        if (_deadline < block.timestamp) revert SigDeadlineExpired();

        bytes32 msgHash = keccak256(
            abi.encode(
                _SIGNED_GASLESS_DATA_TYPEHASH,
                _transactionId,
                _user,
                _dustReceiver,
                nonce[_user],
                _deadline,
                _zapDataHash,
                _feeDataHash,
                _executorFeeDataHash,
                _crosschainDataHash,
                _sweepDustHash
            )
        );

        _verifySignature(_user, msgHash, _userIntentSignature);

        unchecked {
            ++nonce[_user];
        }
    }

    /// @notice Creates witness hash for gasless batch permit2 operations
    /// @param _transactionId Unique transaction identifier
    /// @param _user User address
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _userNonce Current user nonce
    /// @param _deadline Signature expiration timestamp
    /// @param _zapDataHash Hash of zap execution data
    /// @param _feeDataHash Hash of fee configuration
    /// @param _executorFeeDataHash Hash of executor fee data
    /// @param _crosschainDataHash Hash of crosschain data
    /// @param _sweepDustHash Hash of sweep dust data
    /// @return witness Computed witness hash for permit2
    function _createGaslessWitness(
        bytes32 _transactionId,
        address _user,
        address _dustReceiver,
        uint256 _userNonce,
        uint256 _deadline,
        bytes32 _zapDataHash,
        bytes32 _feeDataHash,
        bytes32 _executorFeeDataHash,
        bytes32 _crosschainDataHash,
        bytes32 _sweepDustHash
    ) internal pure returns (bytes32 witness) {
        witness = keccak256(
            abi.encode(
                _GASLESS_WITNESS_TYPEHASH,
                _transactionId,
                _user,
                _dustReceiver,
                _userNonce,
                _deadline,
                _zapDataHash,
                _feeDataHash,
                _executorFeeDataHash,
                _crosschainDataHash,
                _sweepDustHash
            )
        );
    }
}
