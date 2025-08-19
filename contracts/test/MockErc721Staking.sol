// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MockErc721Staking is ERC721Holder {
    using SafeERC20 for IERC20;

    address nftToken;
    address token;
    uint256 mockRewards;

    // -------------------------------

    constructor(address _nftToken, address _token, uint256 _mockRewards) {
        require(_mockRewards > 0, "Invalid Amount");
        nftToken = _nftToken;
        token = _token;
        mockRewards = _mockRewards;
    }

    function setMockRewards(uint256 _mockRewards) external {
        require(_mockRewards > 0, "Invalid Amount");
        mockRewards = _mockRewards;
    }

    function deposit(address _nftToken, uint256 _tokenId, bool _alreadyTransfered) external {
        if (_alreadyTransfered) {
            require(IERC721(_nftToken).ownerOf(_tokenId) == address(this), "NFT not transfered");
        } else {
            IERC721(_nftToken).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
    }

    function withdraw(address _nftToken, address _recipient, uint256 _tokenId) external {
        IERC721(_nftToken).safeTransferFrom(address(this), _recipient, _tokenId);
        IERC20(token).safeTransfer(_recipient, mockRewards);
    }
}
