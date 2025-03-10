// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "hardhat/console.sol";

library LibValidator {
    error InvalidSignatureLength();
    error QuorumNotReached();
    error SignatureAlreadyProcessed();
    error NotAValidator(uint256, address);

    /**
     * @dev Validates provided signatures. Only the first `_quorum` signatures are processed,
     * and these signatures must be from distinct validators.
     *
     * The expected `_signatures` layout is as follows:
     *   - Byte 0: `sigsCount` (number of signatures, as a uint8)
     *   - Next `65 * sigsCount` bytes: Each signature is a standard 65-byte ECDSA signature,
     *     where the signature is the concatenation of `r` (32 bytes), `s` (32 bytes), and `v` (1 byte).
     *
     * Total expected length: 1 + (65 * sigsCount) bytes.
     *
     * @param _validators Mapping of allowed validator addresses.
     * @param _signatures Encoded signatures in the specified format.
     * @param _hash The digest of the message that was signed (must match the digest used during signing).
     * @param _quorum The minimum number of valid signatures required.
     */
    function verifyValidatorSigs(
        mapping(address => bool) storage _validators,
        bytes memory _signatures,
        bytes32 _hash,
        uint8 _quorum
    ) internal view {
        console.log("---------verifyValidatorSigs----------", _quorum);

        // Ensure there is at least one byte to read the signature count.
        require(_signatures.length > 0, InvalidSignatureLength());

        // Extract the signature count from the first byte.
        uint8 sigsCount = uint8(_signatures[0]);
        require(sigsCount >= _quorum, QuorumNotReached());

        console.log("sigsCount:", sigsCount);
        console.log("_signatures.length:", _signatures.length);

        uint256 expectedLength = 1 + (65 * sigsCount);
        require(_signatures.length == expectedLength, InvalidSignatureLength());

        address[] memory seenValidators = new address[](_quorum);

        for (uint256 i = 0; i < _quorum; ++i) {
            console.log("-------", i);

            uint256 sigOffset = 1 + (i * 65);
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(_signatures, add(sigOffset, 32)))
                s := mload(add(_signatures, add(sigOffset, 64)))
                v := byte(0, mload(add(_signatures, add(sigOffset, 96))))
            }

            address validator = ECDSA.recover(_hash, v, r, s);
            console.log("validator", validator);

            require(_validators[validator], NotAValidator(i, validator));
            require(!arrayContains(seenValidators, validator), SignatureAlreadyProcessed());
            seenValidators[i] = validator;
        }
    }

    function arrayContains(address[] memory _array, address _value) private pure returns (bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }
}
