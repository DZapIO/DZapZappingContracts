// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { InputErc20Tokens } from "../../zap/Types.sol";

interface IZap {
    // -------------EVENTS-------------

    event FeeVaultSet(address indexed feeVault);
    event ReferralAdded(address indexed referral);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event Zapped(address indexed user, bytes32 indexed transactionId);

    // -------------RESTRICTED-------------

    event TokenRecovered(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Recovered(address indexed token, address indexed recipient, uint256 id);
    event ERC1155Recovered(address indexed token, address indexed recipient, uint256[] ids, uint256[] amounts);

    function setFeeVault(address _feeVault) external;

    function addReferral(address _referral, uint96 _nativeFeeShare, uint96 _tokenFeeShare) external;

    function recoverToken(address _token, address _recipient, uint256 _amount) external;

    function recoverERC721(address _token, address _recipient, uint256 _id) external;

    function recoverERC1155(
        address _token,
        address _recipient,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    // -------------EXTERNAL-------------

    function registerAsReferral() external;

    function zap(
        bytes32 _transactionId,
        bytes calldata _data,
        bytes calldata _signature,
        address _referral,
        InputErc20Tokens[] calldata _inputTokens,
        address[] calldata _sweepDust
    ) external payable;
}
