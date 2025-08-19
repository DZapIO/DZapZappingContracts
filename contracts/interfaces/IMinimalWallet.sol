// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { TokenTransfer, TokenApproval } from "../wallet/Types.sol";

interface IMinimalWallet {
    event WithdrawnNative();
    event WithdrawnErc20();
    event WithdrawnErc721();
    event WithdrawnErc1155();
    event Erc20ApprovalRevoked();
    event Erc721ApprovalRevoked();
    event Erc1155ApprovalRevoked();

    function owner() external returns (address);

    function withdraw(TokenTransfer[] calldata _info) external;

    function withdrawNative(uint256 amount, address recipient) external;

    function withdrawERC20s(IERC20[] calldata erc20s, uint256[] calldata amounts, address[] calldata recipients) external;

    function withdrawERC721s(IERC721[] calldata erc721s, uint256[] calldata ids, address[] calldata recipients) external;

    function withdrawERC1155s(IERC1155 erc1155, uint256[] calldata ids, uint256[] calldata amounts, address recipient) external;

    function revokeApprovals(TokenApproval[] calldata notes) external;

    function revokeERC20Approvals(IERC20 erc20, address[] calldata operators) external;

    function revokeERC721Approvals(IERC721 erc721, address[] calldata operators) external;

    function revokeERC1155Approvals(IERC1155 erc1155, address[] calldata operators) external;
}
