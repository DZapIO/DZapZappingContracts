// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC721URIStorage, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MockErc721 is ERC721URIStorage {
    uint256 private _nextTokenId;

    constructor() ERC721("MockNft", "MN") {}

    // function mint(address user, uint256 noOfNfts) public {
    //     uint256 tempNextId = _nextTokenId;
    //     for (uint256 i; i < noOfNfts; ++i) {
    //         uint256 tokenId = ++tempNextId;
    //         _mint(user, tokenId);
    //     }

    //     _nextTokenId = tempNextId;
    // }
   
    function mint(address user, uint256[] memory nftIds) public {
        for (uint256 i; i < nftIds.length; ++i) {
            _mint(user, nftIds[i]);
        }
    }
}
