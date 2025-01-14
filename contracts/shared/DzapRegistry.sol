// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*  */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ZeroAddress } from "./Errors.sol";

contract DzapRegistry is Ownable {
    // -------------STATE-------------

    mapping(address => bool) private _whitelistedTargets;
    mapping(address => bool) private _whitelistedExecutors; // for DZAP WALLETS
    mapping(address => address) private _whitelistedAdapters;
    mapping(bytes4 => address) private _adaptersMapping;

    // -------------EVENTS-------------

    event WhitelistedExecutorUpdated(address indexed executor, bool whitelisted);
    event WhitelistedTargetsUpdated(address[] targets, bool whitelisted);
    event AdaptersWhitelisted(address[] selectors, address[] adapters);
    event AdaptersUpdated(bytes4[] selectors, address[] adapters);

    // -------------CONSTRUCTOR-------------

    constructor(address _owner) Ownable(_owner) {}

    // -------------VIEW-------------

    function isTargetWhitelisted(address _target) external view returns (bool) {
        return _whitelistedTargets[_target];
    }

    function isExecutorWhitelisted(address _executor) external view returns (bool) {
        return _whitelistedExecutors[_executor];
    }

    function getAdapterForContract(address _contractAddr) external view returns (address) {
        return _whitelistedAdapters[_contractAddr];
    }

    function getAdapterForSelector(bytes4 _selector) external view returns (address) {
        return _adaptersMapping[_selector];
    }

    // -------------EXTERNAL-------------

    function setWhitelistedExecutor(address _executor, bool _whitelisted) external onlyOwner {
        require(_executor != address(0), ZeroAddress());
        _whitelistedExecutors[_executor] = _whitelisted;
        emit WhitelistedExecutorUpdated(_executor, _whitelisted);
    }

    function setWhitelistedTargets(address[] calldata _targests, bool _isApproved) external onlyOwner {
        uint256 length = _targests.length;
        for (uint256 i; i < length; ++i) {
            _whitelistedTargets[_targests[i]] = _isApproved;
        }

        emit WhitelistedTargetsUpdated(_targests, _isApproved);
    }

    function setAdapters(address[] calldata _contractAddr, address[] calldata _adapters) external onlyOwner {
        uint256 length = _contractAddr.length;
        for (uint256 i; i < length; ++i) {
            _whitelistedAdapters[_contractAddr[i]] = _adapters[i];
        }

        emit AdaptersWhitelisted(_contractAddr, _adapters);
    }

    function setAdapters(bytes4[] calldata _selectors, address[] calldata _adapters) external onlyOwner {
        uint256 length = _selectors.length;
        for (uint256 i; i < length; ++i) {
            _adaptersMapping[_selectors[i]] = _adapters[i];
        }

        emit AdaptersUpdated(_selectors, _adapters);
    }
}
