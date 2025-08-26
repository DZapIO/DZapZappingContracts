// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { LibAsset } from "../shared/libraries/LibAsset.sol";
import { DZapCoreBase } from "./DZapCoreBase.sol";
import { InvalidProtocolFeeVault, ZeroAddress, NoTransferToNullAddress, UniswapPermit2AlreadySet, UniswapPermit2ByteCodeMismatch, ProtectedSelector } from "./Errors.sol";

/// @title DZapAdmin
/// @author DZap
/// @notice Abstract contract containing all administrative functions
/// @dev Provides gas-optimized admin operations for contract management
abstract contract DZapAdmin is DZapCoreBase, Pausable {
    // ============= PROTOCOL CONFIGURATION =============

    /// @notice Updates protocol fee vault address
    /// @param _protocolFeeVault New protocol fee vault address
    function setProtocolFeeVault(address _protocolFeeVault) external onlyOwner {
        require(_protocolFeeVault != address(0) && _protocolFeeVault != address(this), InvalidProtocolFeeVault());
        protocolFeeVault = _protocolFeeVault;
        emit ProtocolFeeVaultSet(_protocolFeeVault);
    }

    /// @notice Updates zap verifier address
    /// @param _verifier New verifier address
    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), ZeroAddress());
        zapVerifier = _verifier;
        emit ZapVerifierSet(_verifier);
    }

    /// @notice Updates to Uniswap Permit2 if bytecode matches expected hash
    function updateToUniswapPermit2() external onlyOwnerOrAdmin {
        require(permit2 != UNISWAP_PERMIT2, UniswapPermit2AlreadySet());
        require(keccak256(UNISWAP_PERMIT2.code) == EXPECTED_PERMIT2_RUNTIME_HASH, UniswapPermit2ByteCodeMismatch());
        permit2 = UNISWAP_PERMIT2;
        emit Permit2Updated();
    }

    // ============= ADMIN MANAGEMENT =============

    /// @notice Adds an address as an admin
    /// @param _account Address to add as admin
    function addAdmin(address _account) external onlyOwner {
        admins[_account] = true;
        emit AdminAdded(_account);
    }

    /// @notice Removes an address from admin role
    /// @param _account Address to remove from admin
    function removeAdmin(address _account) external onlyOwner {
        admins[_account] = false;
        emit AdminRemoved(_account);
    }

    // ============= ADAPTER AND SELECTOR MANAGEMENT =============

    /// @notice Updates adapter whitelist status for multiple addresses
    /// @param _adapters Array of adapter addresses to update
    /// @param _whitelisted Whether adapters should be whitelisted
    function whitelistAdapters(address[] calldata _adapters, bool _whitelisted) external onlyOwner {
        uint256 length = _adapters.length;

        for (uint256 i; i < length; ++i) {
            address adapter = _adapters[i];
            require(adapter != address(0), ZeroAddress());
            _adaptersAllowlist[adapter] = _whitelisted;
        }

        emit AdaptersWhitelistingUpdated(_adapters, _whitelisted);
    }

    /// @notice Blocks multiple selectors
    /// @param _selectors Array of selectors to block
    function blockSelectors(bytes4[] calldata _selectors) external onlyOwner {
        uint256 length = _selectors.length;

        for (uint256 i; i < length; ++i) {
            bytes4 selector = _selectors[i];
            blockedSelectors[selector] = true;
        }

        emit SelectorsBlacklistingUpdated(_selectors, true);
    }

    /// @notice Unblocks multiple selectors
    /// @param _selectors Array of selectors to unblock
    function unblockSelectors(bytes4[] calldata _selectors) external onlyOwner {
        uint256 length = _selectors.length;

        for (uint256 i; i < length; ++i) {
            bytes4 selector = _selectors[i];
            require(!_isProtectedSelector(selector), ProtectedSelector(selector));
            blockedSelectors[selector] = false;
        }

        emit SelectorsBlacklistingUpdated(_selectors, false);
    }

    // ============= EMERGENCY RECOVERY =============

    /// @notice Recovers stuck ERC20/native tokens from the contract
    /// @param _token Token address (use LibAsset._NATIVE_TOKEN for native)
    /// @param _recipient Recovery recipient address
    /// @param _amount Amount to recover
    function recoverToken(address _token, address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferToken(_token, _recipient, _amount);
        emit TokenRecovered(_token, _recipient, _amount);
    }

    /// @notice Recovers stuck ERC721 tokens from the contract
    /// @param _token ERC721 contract address
    /// @param _recipient Recovery recipient address
    /// @param _id Token ID to recover
    function recoverERC721(address _token, address _recipient, uint256 _id) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferERC721(_token, _recipient, _id);
        emit ERC721Recovered(_token, _recipient, _id);
    }

    /// @notice Recovers stuck ERC1155 tokens from the contract
    /// @param _token ERC1155 contract address
    /// @param _recipient Recovery recipient address
    /// @param _ids Array of token IDs to recover
    /// @param _amounts Array of amounts to recover for each ID
    function recoverERC1155(address _token, address _recipient, uint256[] calldata _ids, uint256[] calldata _amounts) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferBatchERC1155(_token, _recipient, _ids, _amounts);
        emit ERC1155Recovered(_token, _recipient, _ids, _amounts);
    }

    // ============= PAUSE FUNCTIONALITY =============

    /// @notice Pauses contract operations
    function pause() external onlyOwnerOrAdmin whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract operations
    function unpause() external onlyOwnerOrAdmin whenPaused {
        _unpause();
    }

    // solhint-disable-next-line code-complexity
    function _isProtectedSelector(bytes4 selector) private pure returns (bool) {
        if (selector == bytes4(0)) return true;

        // ERC20 functions
        if (selector == IERC20.approve.selector) return true;
        if (selector == IERC20.transfer.selector) return true;
        if (selector == IERC20.transferFrom.selector) return true;

        // ERC721 functions
        if (selector == IERC721.approve.selector) return true;
        if (selector == IERC721.transferFrom.selector) return true;
        if (selector == IERC721.setApprovalForAll.selector) return true;
        if (selector == bytes4(keccak256("safeTransferFrom(address,address,uint256)"))) return true;
        if (selector == bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))) return true;

        // ERC1155 functions
        if (selector == IERC1155.safeTransferFrom.selector) return true;
        if (selector == IERC1155.safeBatchTransferFrom.selector) return true;
        if (selector == IERC1155.setApprovalForAll.selector) return true;

        return false;
    }
}
