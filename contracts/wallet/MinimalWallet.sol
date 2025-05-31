// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { InvalidAccount } from "../shared/Errors.sol";
import { TokenType, TokenTransfer, TokenApproval } from "./Types.sol";
import { ZeroAddress } from "../shared/Errors.sol";

import { IMinimalWallet } from "../interfaces/IMinimalWallet.sol";
import { OwnableUnauthorizedAccount, InvalidArrayLength, WithdrawFailed } from "../shared/Errors.sol";

/* From enso base wallet : https://github.com/EnsoBuild/shortcuts-contracts/blob/a575b19e02139137d1056514112087bb80f8ce96/contracts/wallet/MinimalWallet.sol */
abstract contract MinimalWallet is ERC721Holder, ERC1155Holder, IMinimalWallet {
    using SafeERC20 for IERC20;

    address public owner;

    //--------------------MODIFIERS----------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, OwnableUnauthorizedAccount(msg.sender));
        _;
    }

    //--------------------INITIALIZER----------------------------

    function _setOwner(address _owner) internal {
        require(_owner != address(0), InvalidAccount());
        owner = _owner;
    }

    //--------------------EXTERNAL----------------------------

    // @notice Withdraw an array of assets
    // @dev Works for ETH, ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the tokenType id, token address, array of ids and amounts
    // solhint-disable-next-line code-complexity
    function withdraw(TokenTransfer[] calldata _info) external onlyOwner {
        TokenTransfer memory transferInfo;
        TokenType tokenType;
        uint256[] memory ids;
        uint256[] memory amounts;

        uint256 length = _info.length;
        for (uint256 i; i < length; ++i) {
            transferInfo = _info[i];
            tokenType = transferInfo.tokenType;
            if (tokenType == TokenType.ETH) {
                amounts = transferInfo.amounts;
                require(amounts.length == 1, InvalidArrayLength());
                _withdrawETH(amounts[0], transferInfo.recipient);
            } else if (tokenType == TokenType.ERC20) {
                amounts = transferInfo.amounts;
                require(amounts.length == 1, InvalidArrayLength());
                _withdrawERC20(IERC20(transferInfo.token), amounts[0], transferInfo.recipient);
            } else if (tokenType == TokenType.ERC721) {
                ids = transferInfo.ids;
                _withdrawERC721s(IERC721(transferInfo.token), ids[0], transferInfo.recipient);
            } else if (tokenType == TokenType.ERC1155) {
                ids = transferInfo.ids;
                amounts = transferInfo.amounts;
                _withdrawERC1155s(IERC1155(transferInfo.token), ids, amounts, transferInfo.recipient);
            }
        }
    }

    // @notice Withdraw ETH from this contract to the msg.sender
    // @param amount The amount of ETH to be withdrawn
    function withdrawETH(uint256 amount, address recipient) external onlyOwner {
        _withdrawETH(amount, recipient);
    }

    // @notice Withdraw ERC20s
    // @param erc20s An array of erc20 addresses
    // @param amounts An array of amounts for each erc20
    function withdrawERC20s(IERC20[] calldata erc20s, uint256[] calldata amounts, address[] calldata recipients) external onlyOwner {
        uint256 length = erc20s.length;
        require(amounts.length == length, InvalidArrayLength());
        for (uint256 i; i < length; ++i) {
            require(recipients[i] != address(0), ZeroAddress());
            _withdrawERC20(erc20s[i], amounts[i], recipients[i]);
        }
    }

    // @notice Withdraw multiple ERC721 ids for a single ERC721 contract
    // @param erc721 The address of the ERC721 contract
    // @param ids An array of ids that are to be withdrawn
    function withdrawERC721s(IERC721[] calldata erc721s, uint256[] calldata ids, address[] calldata recipients) external onlyOwner {
        uint256 length = ids.length;
        for (uint256 i; i < length; ++i) {
            _withdrawERC721s(erc721s[i], ids[i], recipients[i]);
        }
    }

    // @notice Withdraw multiple ERC1155 ids for a single ERC1155 contract
    // @param erc1155 The address of the ERC155 contract
    // @param ids An array of ids that are to be withdrawn
    // @param amounts An array of amounts per id
    function withdrawERC1155s(IERC1155 erc1155, uint256[] calldata ids, uint256[] calldata amounts, address recipient) external onlyOwner {
        _withdrawERC1155s(erc1155, ids, amounts, recipient);
    }

    // @notice Revoke approval on an array of assets and operators
    // @dev Works for ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the tokenType id, token address, and array of operators
    function revokeApprovals(TokenApproval[] calldata notes) external onlyOwner {
        TokenApproval memory transferInfo;
        TokenType tokenType;

        uint256 length = notes.length;
        for (uint256 i; i < length; ++i) {
            transferInfo = notes[i];
            tokenType = transferInfo.tokenType;
            if (tokenType == TokenType.ERC20) {
                _revokeERC20Approvals(IERC20(transferInfo.token), transferInfo.operators);
            } else if (tokenType == TokenType.ERC721) {
                _revokeERC721Approvals(IERC721(transferInfo.token), transferInfo.operators);
            } else if (tokenType == TokenType.ERC1155) {
                _revokeERC1155Approvals(IERC1155(transferInfo.token), transferInfo.operators);
            }
        }
    }

    // @notice Revoke approval of an ERC20 for an array of operators
    // @param erc20 The address of the ERC20 token
    // @param operators The array of operators to have approval revoked
    function revokeERC20Approvals(IERC20 erc20, address[] calldata operators) external onlyOwner {
        _revokeERC20Approvals(erc20, operators);
    }

    // @notice Revoke approval of an ERC721 for an array of operators
    // @param erc721 The address of the ERC721 token
    // @param operators The array of operators to have approval revoked
    function revokeERC721Approvals(IERC721 erc721, address[] calldata operators) external onlyOwner {
        _revokeERC721Approvals(erc721, operators);
    }

    // @notice Revoke approval of an ERC1155 for an array of operators
    // @param erc1155 The address of the ERC1155 token
    // @param operators The array of operators to have approval revoked
    function revokeERC1155Approvals(IERC1155 erc1155, address[] calldata operators) external onlyOwner {
        _revokeERC1155Approvals(erc1155, operators);
    }

    //--------------------INTERNAL----------------------------

    function _withdrawETH(uint256 amount, address recipient) internal {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, WithdrawFailed());
    }

    function _withdrawERC20(IERC20 erc20, uint256 amount, address recipient) internal {
        erc20.safeTransfer(recipient, amount);
    }

    function _withdrawERC721s(IERC721 erc721, uint256 ids, address recipient) internal {
        require(recipient != address(0), ZeroAddress());
        erc721.safeTransferFrom(address(this), recipient, ids);
    }

    function _withdrawERC1155s(IERC1155 erc1155, uint256[] memory ids, uint256[] memory amounts, address recipient) internal {
        // safeBatchTransferFrom will validate the array lengths
        erc1155.safeBatchTransferFrom(address(this), recipient, ids, amounts, "");
    }

    function _revokeERC20Approvals(IERC20 erc20, address[] memory operators) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ++i) {
            erc20.approve(operators[i], 0);
        }
    }

    function _revokeERC721Approvals(IERC721 erc721, address[] memory operators) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ++i) {
            erc721.setApprovalForAll(operators[i], false);
        }
    }

    function _revokeERC1155Approvals(IERC1155 erc1155, address[] memory operators) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ++i) {
            erc1155.setApprovalForAll(operators[i], false);
        }
    }

    //--------------------RECEIVE/FALLBACK---------------------

    receive() external payable {}
}
