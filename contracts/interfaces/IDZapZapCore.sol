// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { InputErc20Tokens } from "../zap/Types.sol";

interface IDZapZapCore {
    // -------------EVENTS-------------

    event DefaultReferralFeeSet(uint256 defaultReferralNativeFeeShare, uint256 defaultReferralTokenFeeShare);
    event FeeVaultSet(address indexed feeVault);
    event ZapVerifierSet(address indexed verifier);
    event ReferralAdded(address indexed referral);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event Zapped(address indexed user, bytes32 indexed txId);
    event TokenRecovered(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Recovered(address indexed token, address indexed recipient, uint256 id);
    event ERC1155Recovered(address indexed token, address indexed recipient, uint256[] ids, uint256[] amounts);

    // -------------RESTRICTED-------------

    function setDefaultReferralFee(uint96 _defaultReferralNativeFeeShare,uint96 _defaultReferralTokenFeeShare) external;

    function setFeeVault(address _feeVault) external;

    function setVerifier(address _verifier) external;

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
        address[] calldata _sweepDust,
        address _dustReciever
    ) external payable;
}
