// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { NativeTransferFailed } from "../../shared/Errors.sol";

contract DisperseEthAdapter {
    function transferEth(address[] calldata _recipients, uint256[] calldata _amount) external payable {
        uint256 length = _recipients.length;
        for (uint256 i; i < length; ++i) {
            (bool success, ) = _recipients[i].call{ value: _amount[i] }("");
            require(success, NativeTransferFailed());
        }
    }

    function transferEth(address _recipient, uint256 _amount) external payable {
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, NativeTransferFailed());
    }
}
