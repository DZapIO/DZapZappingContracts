// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { PermitType } from "../Types.sol";
import { LibPermit } from "./LibPermit.sol";

import { NativeTransferFailed, NoTransferToNullAddress, InvalidAmount, NullAddrIsNotAValidSpender } from "../Errors.sol";

// import "hardhat/console.sol";
library LibAsset {
    using SafeERC20 for IERC20;

    address internal constant _NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // -------------VIEWS-------------

    function selfNativeBalance() internal view returns (uint256 contractBalance) {
        assembly {
            contractBalance := selfbalance()
        }
    }

    function getBalance(address _token, address _account) internal view returns (uint256) {
        return _token == _NATIVE_TOKEN ? _account.balance : IERC20(_token).balanceOf(_account);
    }

    function getOwnerOfERC721(address _token, uint256 _id) internal view returns (address) {
        return IERC721(_token).ownerOf(_id);
    }
    function getBalanceOfERC1155(address _token, address _account, uint256 _id) internal view returns (uint256) {
        return IERC1155(_token).balanceOf(_account, _id);
    }

    // -------------HELPERS-------------

    function transferToken(address _token, address _to, uint256 _amount) internal {
        if (_amount != 0) {
            if (_token == _NATIVE_TOKEN) transferNativeToken(_to, _amount);
            else transferERC20(_token, _to, _amount);
        }
    }

    function transferNativeToken(address _to, uint256 _amount) internal {
        require(_to != address(0), NoTransferToNullAddress());
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, NativeTransferFailed());
    }

    function transferERC20(address _token, address _to, uint256 _amount) internal {
        SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
    }

    function transferFromERC20(address _token, address _from, address _to, uint256 _amount) internal {
        IERC20 token = IERC20(_token);
        uint256 prevBalance = token.balanceOf(_to);
        SafeERC20.safeTransferFrom(token, _from, _to, _amount);
        require(token.balanceOf(_to) - prevBalance == _amount, InvalidAmount());
    }

    function approveERC20(address _token, address _spender, uint256 _amount) internal {
        require(_spender != address(0), NullAddrIsNotAValidSpender());
        revokeERC20(_token, _spender);
        SafeERC20.safeIncreaseAllowance(IERC20(_token), _spender, _amount);
    }

    function revokeERC20(address _token, address _spender) internal {
        uint256 allowance = IERC20(_token).allowance(address(this), _spender);
        if (allowance != 0) SafeERC20.safeDecreaseAllowance(IERC20(_token), _spender, allowance);
    }

    function approveERC721(address _token, address _to, uint256 _tokenId) internal {
        require(_to != address(0), NullAddrIsNotAValidSpender());
        IERC721(_token).approve(_to, _tokenId);
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

    function approveERC1155(address _token, address _spender) internal {
        IERC1155(_token).setApprovalForAll(_spender, true);
    }

    function revokeERC1155(address _token, address _spender) internal {
        IERC1155(_token).setApprovalForAll(_spender, false);
    }

    function depositErc20(address _permit2, address _token, address _from, address _to, uint256 _amount, bytes memory permit_) internal {
        (PermitType permitType, bytes memory data) = abi.decode(permit_, (PermitType, bytes));

        if (permitType == PermitType.PERMIT2) LibPermit.permit2ApproveAndTransfer(_permit2, _from, _to, uint160(_amount), _token, data);
        else {
            if (data.length != 0) LibPermit.permit(_token, data);
            transferFromERC20(_token, _from, _to, _amount);
        }
    }
}
