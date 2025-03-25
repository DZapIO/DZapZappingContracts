// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IDZapRegistry } from "../interfaces/IDZapRegistry.sol";
import { ZeroAddress } from "../shared/Errors.sol";

/*  
---------------------------------------------------------
---------------------------------------------------------

 /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$ 
| $$__  $$|_____ $$  /$$__  $$| $$__  $$
| $$  \ $$     /$$/ | $$  \ $$| $$  \ $$
| $$  | $$    /$$/  | $$$$$$$$| $$$$$$$/
| $$  | $$   /$$/   | $$__  $$| $$____/ 
| $$  | $$  /$$/    | $$  | $$| $$      
| $$$$$$$/ /$$$$$$$$| $$  | $$| $$      
|_______/ |________/|__/  |__/|__/      


Author: DZap <https://dzap.io> (https://x.com/dzap_io)

---------------------------------------------------------
---------------------------------------------------------
*/

contract DZapRegistry is Ownable, IDZapRegistry {
    // -------------STATE-------------

    mapping(address executor => bool isWhitelisted) private _executors;

    // -------------EVENTS-------------

    event ExecutorWhitelistingUpdated(address indexed executor, bool isWhitelisted);

    // -------------CONSTRUCTOR-------------

    constructor(address _owner) Ownable(_owner) {}

    // -------------VIEW-------------

    function isExecutorWhitelisted(address _executor) external view returns (bool) {
        return _executors[_executor];
    }

    // -------------EXTERNAL-------------

    function setExecutorWhitelisting(address _executor, bool _whitelisted) external onlyOwner {
        require(_executor != address(0), ZeroAddress());
        _executors[_executor] = _whitelisted;
        emit ExecutorWhitelistingUpdated(_executor, _whitelisted);
    }
}
