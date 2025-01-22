// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockErc1155 is ERC1155 {
    uint256 private _nextTokenId;

    constructor() ERC1155("") {}

    function mint(address user, uint256 _id, uint256 _amount) public {
        _mint(user, _id, _amount, "");
    }
}
