// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "../../interfaces/IPermit2.sol";

/// @title LibPermit
/// @notice This library contains helpers for using permit and permit2
library LibPermit {
    error InvalidPermitData();
    error InvalidPermit();

    function permit2ApproveAndTransfer(address _permit2, address _from, address _to, uint160 _amount, address _token, bytes memory _data) internal {
        if (_data.length != 0) {
            (uint160 allowanceAmount, uint48 nonce, uint48 expiration, uint256 sigDeadline, bytes memory signature) = abi.decode(_data, (uint160, uint48, uint48, uint256, bytes));
            IPermit2(_permit2).permit(msg.sender, IPermit2.PermitSingle(IPermit2.PermitDetails(_token, allowanceAmount, expiration, nonce), address(this), sigDeadline), signature);
        }
        IPermit2(_permit2).transferFrom(_from, _to, uint160(_amount), _token);
    }

    function permit(address _token, bytes memory _data) internal {
        if (_data.length == 32 * 7) {
            (bool success, ) = _token.call(bytes.concat(IERC20Permit.permit.selector, _data));
            require(success, InvalidPermit());
        } else revert InvalidPermitData();
    }
}
