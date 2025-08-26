// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { PermitTransferFrom, PermitBatchTransferFrom, SignatureTransferDetails, PermitSingle, PermitDetails, TokenPermissions, IPermit2 } from "../../interfaces/IPermit2.sol";

/**
 * @title LibPermit
 * @author DZap
 * @notice This library contains helpers for using permit and permit2
 */
library LibPermit {
    // ============= ERRORS =============

    error InvalidPermit(string reason);

    // ============= CONSTANTS =============

    string internal constant _DZAP_TRANSFER_WITNESS_TYPE_STRING =
        "DZapTransferWitness witness)DZapTransferWitness(address owner,address recipient)TokenPermissions(address token,uint256 amount)";
    bytes32 internal constant _DZAP_TRANSFER_WITNESS_TYPEHASH = keccak256("DZapTransferWitness(address owner,address recipient)");

    // ============= EIP-2612 PERMIT FUNCTIONS =============

    /// @notice Handles eip2612 permit
    function eip2612Permit(address _owner, address _spender, address _token, uint256 _amount, bytes memory _data) internal {
        (uint256 deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(_data, (uint256, uint8, bytes32, bytes32));
        IERC20Permit(_token).permit(_owner, _spender, _amount, deadline, v, r, s);
    }

    // ============= PERMIT2 FUNCTIONS =============

    /// @notice Handles permit2 approve and transfer
    function permit2ApproveAndTransfer(address _permit2, address _from, address _to, address _token, uint160 _amount, bytes memory data) internal {
        permit2Approve(_permit2, _from, _to, _token, _amount, data);
        IPermit2(_permit2).transferFrom(_from, _to, uint160(_amount), _token);
    }

    /// @notice Handles permit2 approve
    function permit2Approve(address _permit2, address _owner, address _spender, address _token, uint160 _amount, bytes memory _data) internal {
        if (_data.length == 0) return;
        IPermit2 permit2Contract = IPermit2(_permit2);
        (uint48 nonce, uint48 expiration, uint256 sigDeadline, bytes memory signature) = abi.decode(_data, (uint48, uint48, uint256, bytes));

        try
            permit2Contract.permit(_owner, PermitSingle(PermitDetails(_token, _amount, expiration, nonce), _spender, sigDeadline), signature)
        {} catch Error(string memory reason) {
            (uint256 currentAllowance, uint256 allowanceExpiration, ) = permit2Contract.allowance(_owner, _token, _spender);
            require(currentAllowance >= _amount && allowanceExpiration >= block.timestamp, InvalidPermit(reason));
        }
    }

    /// @notice Handles permit2 witness transfer from
    function permit2WitnessTransferFrom(
        address _permit2,
        address _owner,
        address _recipient,
        address _token,
        uint256 _amount,
        bytes memory _data
    ) internal {
        (uint256 nonce, uint256 deadline, bytes memory _signature) = abi.decode(_data, (uint256, uint256, bytes));

        IPermit2(_permit2).permitWitnessTransferFrom(
            PermitTransferFrom(TokenPermissions(_token, _amount), nonce, deadline),
            SignatureTransferDetails(_recipient, _amount),
            _owner,
            _createWitnessTransferFromHash(_owner, _recipient),
            _DZAP_TRANSFER_WITNESS_TYPE_STRING,
            _signature
        );
    }

    /// @notice Handles permit2 batch witness transfer from
    function permit2BatchWitnessTransferFrom(
        address _permit2,
        address _owner,
        address _recipient,
        PermitBatchTransferFrom calldata permit,
        bytes calldata _signature
    ) internal {
        uint256 length = permit.permitted.length;
        SignatureTransferDetails[] memory details = new SignatureTransferDetails[](length);

        for (uint256 i; i < length; ++i) {
            details[i] = SignatureTransferDetails(_recipient, permit.permitted[i].amount);
        }

        IPermit2(_permit2).permitWitnessTransferFrom(
            permit,
            details,
            _owner,
            _createWitnessTransferFromHash(_owner, _recipient),
            _DZAP_TRANSFER_WITNESS_TYPE_STRING,
            _signature
        );
    }

    /// @notice Handles permit2 batch witness transfer from
    function permit2BatchWitnessTransferFrom(
        address _permit2,
        address _owner,
        address _recipient,
        bytes32 _witness,
        PermitBatchTransferFrom calldata permit,
        bytes calldata _signature,
        string memory _witnessTypeString
    ) internal {
        uint256 length = permit.permitted.length;
        SignatureTransferDetails[] memory details = new SignatureTransferDetails[](length);

        for (uint256 i; i < length; ++i) {
            details[i] = SignatureTransferDetails(_recipient, permit.permitted[i].amount);
        }

        IPermit2(_permit2).permitWitnessTransferFrom(permit, details, _owner, _witness, _witnessTypeString, _signature);
    }

    /* ========= PRIVATE ========= */

    function _createWitnessTransferFromHash(address _owner, address _recipient) private pure returns (bytes32) {
        return keccak256(abi.encode(_DZAP_TRANSFER_WITNESS_TYPEHASH, _owner, _recipient));
    }
}
