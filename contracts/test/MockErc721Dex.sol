// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";

contract MockErc721Dex is ERC721Holder {
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

    struct Order {
        uint256 price;
        address token;
        address account; // seller or buyer
        bool isActive;
    }

    // NFT contract => NFT ID
    mapping(address => mapping(uint256 => Order)) public sellOrders; // => Sell Order
    mapping(address => mapping(uint256 => Order)) public buyOrders; // NFT contract => Buyer Address => Buy Order
    mapping(address nft => mapping(address token => uint256 price)) public nftPrice;

    // -------------------------------

    function setNftPrices(address _nftAddress, address _token, uint256 _price) external {
        require(_price > 0, "Invalid price");
        nftPrice[_nftAddress][_token] = _price;
    }

    function swapTokenToNft(
        address _token,
        address _nftAddress,
        address _recipient,
        uint256 _nftId
    ) external payable {
        console.log("----swapErc20ToNft-------");
        uint256 price = nftPrice[_nftAddress][_token];
        console.log("price", price);
        require(price > 0, "Price Not set");
        
        if(isNative(_token)) {
            require(msg.value == price, "Insufficient payment");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), price);
        }
        IERC721(_nftAddress).safeTransferFrom(address(this), _recipient, _nftId);
    }
   
    function swapNftToToken(
        address _nftAddress,
        address _token,
        address _recipient,
        uint256 _nftId,
        bool _alreadyTransfered
    ) external {
        console.log("----swapNftToErc20-------");
        uint256 price = nftPrice[_nftAddress][_token];
        console.log("price", price);
        require(price > 0, "Price Not set");


        if(_alreadyTransfered) {
            require(IERC721(_nftAddress).ownerOf(_nftId) == address(this), "NFT not transfered");
        } else {
            IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _nftId);
        }

        if(isNative(_token)) {
            (bool success, ) = _recipient.call{ value: price }("");
            require(success, "NativeTransferFailed");
        } else {
            IERC20(_token).transfer(_recipient, price);
        }
    }

    function createSellOrder(address _nftAddress, address _token, uint256 _nftId, uint256 _price) external {
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_nftId) == msg.sender, "Caller is not NFT owner");
        require(nft.getApproved(_nftId) == address(this), "NFT not approved for transfer");

        sellOrders[_nftAddress][_nftId] = Order({ price: _price, token: _token, account: msg.sender, isActive: true });
    }

    function createBuyOrder(address _nftAddress, address _token, uint256 _nftId, uint256 _price) external {
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _price, "Token allowance insufficient");

        buyOrders[_nftAddress][_nftId] = Order({ price: _price, token: _token, account: msg.sender, isActive: true });
    }

    // -------------------------------

    function isNative(address token_) private pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    // -------------------------------

    function buyNft(address _nftAddress, address _recipient, uint256 _amount, uint256 _nftId) external payable {
        Order storage order = sellOrders[_nftAddress][_nftId];
        IERC721 nft = IERC721(_nftAddress);

        require(order.isActive, "Sell order does not exist");
        require(order.price == _amount, "Price dees not match");

        if (isNative(order.token)) {
            require(msg.value >= order.price, "Insufficient payment");
            (bool success, ) = order.account.call{ value: order.price }("");
            if (!success) revert NativeTransferFailed();
        } else {
            IERC20 token = IERC20(order.token);
            token.safeTransferFrom(msg.sender, order.account, order.price);
        }

        nft.safeTransferFrom(order.account, _recipient, _nftId);

        delete sellOrders[_nftAddress][_nftId];
    }

    function sellNft(address _nftAddress, address _recipient, uint256 _amount, uint256 _nftId) external payable {
        Order storage order = buyOrders[_nftAddress][_nftId];
        IERC721 nft = IERC721(_nftAddress);

        require(order.isActive, "Buy order does not exist");
        require(order.price == _amount, "Price dees not match");

        nft.safeTransferFrom(msg.sender, order.account, _nftId);

        if (isNative(order.token)) {
            require(msg.value >= order.price, "Insufficient payment");
            (bool success, ) = _recipient.call{ value: order.price }("");
            if (!success) revert NativeTransferFailed();
        } else {
            IERC20 token = IERC20(order.token);
            token.safeTransferFrom(order.account, _recipient, order.price);
        }

        delete buyOrders[_nftAddress][_nftId];
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
