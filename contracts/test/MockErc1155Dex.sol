// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MockErc1155Dex is ERC1155Holder {
    using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error NativeTransferFailed();
    error InvalidNativeSend(uint256 required, uint256 sent);
    error SwapFailedFromExchange();
    error OrderAlreadyExists();
    error OrderNotFound();
    error InsufficientPayment();
    error NFTNotApproved();
    error TokensNotApproved();

    // -------------------------------

    mapping(address nft => mapping(address token => uint256 price)) public nftPrice;

    // -------------------------------

    function setNftPrices(address _nftAddress, address _token, uint256 _price) external {
        require(_price > 0, "Invalid price");
        nftPrice[_nftAddress][_token] = _price;
    }

    function swapTokenToNft(address _token, address _nftAddress, address _recipient, uint256 _nftId, uint256 _amount) external payable {
        uint256 price = nftPrice[_nftAddress][_token];
        require(price > 0, "Price Not set");

        uint256 totalPrice = _amount * price;

        if (isNative(_token)) {
            require(msg.value == totalPrice, "Insufficient payment");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), totalPrice);
        }

        IERC1155(_nftAddress).safeTransferFrom(address(this), _recipient, _nftId, _amount, "");
    }

    function swapNftToToken(
        address _nftAddress,
        address _token,
        address _recipient,
        uint256 _nftId,
        uint256 _amount,
        bool _alreadyTransfered
    ) external {
        uint256 price = nftPrice[_nftAddress][_token];
        require(price > 0, "Price Not set");

        uint256 totalPrice = _amount * price;

        if (_alreadyTransfered) {
            require(IERC1155(_nftAddress).balanceOf(address(this), _nftId) == _amount, "NFT not transfered");
        } else {
            IERC1155(_nftAddress).safeTransferFrom(msg.sender, address(this), _nftId, _amount, "");
        }

        if (isNative(_token)) {
            (bool success, ) = _recipient.call{ value: totalPrice }("");
            require(success, "NativeTransferFailed");
        } else {
            IERC20(_token).transfer(_recipient, totalPrice);
        }
    }

    function swapNftToNft(
        address _srcNftAddress,
        address _destNftAddress,
        address _recipient,
        uint256 _srcNftId,
        uint256 _destNftId,
        uint256 _amount,
        bool _alreadyTransfered
    ) external {
        if (_alreadyTransfered) {
            require(IERC1155(_srcNftAddress).balanceOf(address(this), _srcNftId) > _amount, "NFT not transfered");
        } else {
            IERC1155(_srcNftAddress).safeTransferFrom(msg.sender, address(this), _srcNftId, _amount, "");
        }
        IERC1155(_destNftAddress).safeTransferFrom(address(this), _recipient, _destNftId, _amount, "");
    }

    // -------------------------------

    function isNative(address token_) private pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    // -------------------------------

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
