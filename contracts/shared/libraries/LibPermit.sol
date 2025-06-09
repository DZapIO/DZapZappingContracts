// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IPermit2 } from "../../interfaces/IPermit2.sol";

/// @title LibPermit
/// @notice This library contains helpers for using permit and permit2
library LibPermit {
    error InvalidPermitData();
    error InvalidPermit();

    function permit2ApproveAndTransfer(address _permit2, address _from, address _to, uint160 _amount, address _token, bytes memory _data) internal {
        if (_data.length > 0) {
            (, uint48 nonce, uint48 expiration, uint256 sigDeadline, bytes memory signature) = abi.decode(_data, (uint160, uint48, uint48, uint256, bytes));
            try IPermit2(_permit2).permit(_from, IPermit2.PermitSingle(IPermit2.PermitDetails(_token, _amount, expiration, nonce), _to, sigDeadline), signature) {}
            catch {
                (uint256 currentAllowance, uint256 allowanceExpiration,) = IPermit2(_permit2).allowance(_from, _to, _token);
                require(currentAllowance >= _amount && allowanceExpiration > block.timestamp, InvalidPermit());
            }
        }
        IPermit2(_permit2).transferFrom(_from, _to, _amount, _token);
    }

    function permit(address _token, address _from, address _to, uint256 _amount, bytes memory _data) internal {
        require(_data.length == 32 * 7, InvalidPermitData());
        (, , , uint256 deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(_data, (address, address, uint256, uint256, uint8, bytes32, bytes32));
        try IERC20Permit(_token).permit(_from, _to, _amount, deadline, v, r, s) {} 
        catch {
            require(IERC20(_token).allowance(_from, _to) >= _amount, InvalidPermit());
        }
    }
}
