// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IPermit2, PermitBatchTransferFrom } from "../../interfaces/IPermit2.sol";
import { InputErc20Tokens, PermitType } from "../../zap/Types.sol";
import { LibPermit } from "./LibPermit.sol";

/**
 * @title LibAsset
 * @author DZap
 * @notice This library contains helpers for dealing with onchain transfers
 *         of assets, including accounting for the native asset `assetId`
 *         conventions and any noncompliant ERC20 transfers
 */
library LibAsset {
    using SafeERC20 for IERC20;

    // ============= ERRORS =============

    error NativeTransferFailed();
    error NoTransferToNullAddress();
    error NullAddrIsNotAValidSpender();
    error InvalidAmount();
    error InvalidPermitType();

    // ============= CONSTANTS =============

    address internal constant _NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // ============= BALANCE QUERY FUNCTIONS =============

    function selfNativeBalance() internal view returns (uint256 contractBalance) {
        assembly {
            contractBalance := selfbalance()
        }
    }

    function getErc20Balance(address _token, address _account) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_account);
    }

    function getBalance(address _token, address _account) internal view returns (uint256) {
        return _token == _NATIVE_TOKEN ? _account.balance : IERC20(_token).balanceOf(_account);
    }

    function getNativeBalance(address _account) internal view returns (uint256) {
        return _account.balance;
    }

    function getOwnerOfERC721(address _token, uint256 _id) internal view returns (address) {
        return IERC721(_token).ownerOf(_id);
    }
    function getBalanceOfERC1155(address _token, address _account, uint256 _id) internal view returns (uint256) {
        return IERC1155(_token).balanceOf(_account, _id);
    }

    // ============= TRANSFER FUNCTIONS =============

    function transferToken(address _token, address _to, uint256 _amount) internal {
        if (_token == _NATIVE_TOKEN) transferNativeToken(_to, _amount);
        else transferERC20(_token, _to, _amount);
    }

    function transferNativeToken(address _to, uint256 _amount) internal {
        if (_amount == 0) return;
        require(_to != address(0), NoTransferToNullAddress());

        (bool success, ) = _to.call{ value: _amount }("");
        require(success, NativeTransferFailed());
    }

    function transferERC20(address _token, address _to, uint256 _amount) internal {
        if (_amount == 0) return;

        IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFromERC20(address _token, address _from, address _to, uint256 _amount) internal {
        if (_amount == 0) return;

        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function transferERC721(address _token, address _to, uint256 _id) internal {
        IERC721(_token).safeTransferFrom(address(this), _to, _id);
    }

    function transferERC721(address _token, address _from, address _to, uint256 _id) internal {
        IERC721(_token).safeTransferFrom(_from, _to, _id);
    }

    function transferBatchERC1155(address _token, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        IERC1155(_token).safeBatchTransferFrom(address(this), _to, _ids, _amounts, "");
    }

    function transferERC1155(address _token, address _from, address _to, uint256 _id, uint256 _amount) internal {
        IERC1155(_token).safeTransferFrom(_from, _to, _id, _amount, "");
    }

    // ============= APPROVAL FUNCTIONS =============

    /// @notice If the current allowance is insufficient, then MAX_UINT allowance for a given spender
    function maxApproveERC20(address _token, address _spender, uint256 _amount) internal {
        require(_spender != address(this), NullAddrIsNotAValidSpender());

        uint256 allowance = IERC20(_token).allowance(address(this), _spender);
        if (allowance < _amount) {
            SafeERC20.forceApprove(IERC20(_token), _spender, type(uint256).max);
        }
    }

    function maxPermit2Approve(address _permit2, address _token, address _spender, uint256 _amount) internal {
        require(_spender != address(0), NullAddrIsNotAValidSpender());

        (uint160 allowance, uint48 expiration, ) = IPermit2(_permit2).allowance(address(this), _token, _spender);
        if (allowance < _amount || block.timestamp > expiration) {
            IPermit2(_permit2).approve(_token, _spender, type(uint160).max, type(uint48).max);
        }
    }

    function approveERC721(address _token, address _to, uint256 _tokenId) internal {
        require(_to != address(0), NullAddrIsNotAValidSpender());
        IERC721(_token).approve(_to, _tokenId);
    }

    function approveERC1155(address _token, address _spender) internal {
        IERC1155(_token).setApprovalForAll(_spender, true);
    }

    function revokeERC1155(address _token, address _spender) internal {
        IERC1155(_token).setApprovalForAll(_spender, false);
    }

    // ============= DEPOSIT FUNCTIONS =============

    /// @notice Deposits tokens from a sender to the inheriting contract
    /// @dev only handles erc20 token
    function depositErc20(address _permit2, address _user, address _token, uint256 _amount, bytes calldata _permit) internal {
        (PermitType permitType, bytes memory data) = abi.decode(_permit, (PermitType, bytes));

        if (permitType == PermitType.PERMIT2_WITNESS_TRANSFER) {
            LibPermit.permit2WitnessTransferFrom(_permit2, _user, address(this), _token, _amount, data);
        } else if (permitType == PermitType.PERMIT) {
            if (data.length != 0) LibPermit.eip2612Permit(_user, address(this), _token, _amount, data);
            transferFromERC20(_token, _user, address(this), _amount);
        } else if (permitType == PermitType.PERMIT2_APPROVE) {
            LibPermit.permit2ApproveAndTransfer(_permit2, _user, address(this), _token, uint160(_amount), data);
        } else {
            revert InvalidPermitType();
        }
    }

    function depositBatch(address _permit2, address _user, InputErc20Tokens[] calldata erc20Tokens) internal {
        uint256 length = erc20Tokens.length;
        for (uint256 i; i < length; ++i) {
            depositErc20(_permit2, _user, erc20Tokens[i].token, erc20Tokens[i].amount, erc20Tokens[i].permit);
        }
    }

    function depositBatch(address _permit2, address _user, PermitBatchTransferFrom calldata permit, bytes calldata permitSignature) internal {
        LibPermit.permit2BatchWitnessTransferFrom(_permit2, _user, address(this), permit, permitSignature);
    }

    // ============= UTILITY FUNCTIONS =============

    /// @notice Determines whether the given token is the native token
    function isNativeToken(address _token) internal pure returns (bool) {
        return _token == _NATIVE_TOKEN;
    }
}
