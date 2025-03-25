// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { LibAsset } from "../shared/libraries/LibAsset.sol";
import { FullMath } from "../shared/libraries/FullMath.sol";

import { IDZapZapCore } from "../interfaces/IDZapZapCore.sol";

import { ZapData, TokenType, InputTransferType, OutputTransferType, InputToken, OutputToken, InputErc20Tokens, ReferralFeeInfo, TokenType } from "./Types.sol";
import { InvalidFeeVault, CallFailed, InvalidTokenOwner, InvalidReturnAmount, ZeroAddress, InvalidInputLength, InvalidOutputLength, ReferralAlreadyAdded, ReferralAlreadyAdded, InvalidOutputType, NoTransferToNullAddress, UnauthorizedCaller, UnauthorizedSigner } from "../shared/Errors.sol";

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

contract DZapZapCore is Ownable, ERC721Holder, ERC1155Holder, ReentrancyGuard, IDZapZapCore {
    // -------------STATE-------------

    address public feeVault;
    address public permit2;
    address public verifier;
    uint96 public defaultReferralNativeFeeShare;
    uint96 public defaultReferralTokenFeeShare;

    bytes32 private immutable _DOMAIN_SEPARATOR;

    uint256 private constant _BPS_DENOMINATOR = 1e6; // 4 basis points
    bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 private constant _SIGNED_DATA_TYPEHASH = keccak256("SignedZapData(bytes32 txId,address user,address referral,uint256 nonce,bytes32 data)");

    mapping(address referrer => ReferralFeeInfo feeInfo) public referralFeeInfo;
    mapping(address user => uint256 nonce) public nonce;
    mapping(address admin => bool isAdmin) public admins;

    // -------------MODIFIERS-------------

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || admins[msg.sender], UnauthorizedCaller());
        _;
    }

    modifier refundExcessNative(address _refundee) {
        uint256 initialBalance = LibAsset.selfNativeBalance() - msg.value;
        _;
        uint256 finalBalance = LibAsset.selfNativeBalance();
        if (finalBalance > initialBalance) LibAsset.transferNativeToken(_refundee, finalBalance - initialBalance);
    }

    // -------------CONSTRUCTORS-------------

    constructor(address _owner, address _feeVault, address _verifier, address _permit2, uint96 _defaultReferralNativeFeeShare, uint96 _defaultReferralTokenFeeShare, bytes32 _salt) Ownable(_owner) {
        require(_verifier != address(0) && _permit2 != address(0), ZeroAddress());
        require(_feeVault != address(0) && _feeVault != address(this), InvalidFeeVault());

        feeVault = _feeVault;
        permit2 = _permit2;
        verifier = _verifier;
        defaultReferralNativeFeeShare = _defaultReferralNativeFeeShare;
        defaultReferralTokenFeeShare = _defaultReferralTokenFeeShare;
        _DOMAIN_SEPARATOR = keccak256(abi.encode(_DOMAIN_TYPEHASH, keccak256(bytes("DZapVerifier")), keccak256(bytes("1")), block.chainid, address(this), _salt));
    }

    // -------------RESTRICTED-------------

    function setDefaultReferralFee(uint96 _defaultReferralNativeFeeShare, uint96 _defaultReferralTokenFeeShare) external onlyOwner {
        defaultReferralNativeFeeShare = _defaultReferralNativeFeeShare;
        defaultReferralTokenFeeShare = _defaultReferralTokenFeeShare;
        emit DefaultReferralFeeSet(_defaultReferralNativeFeeShare, _defaultReferralTokenFeeShare);
    }

    function setFeeVault(address _feeVault) external onlyOwner {
        require(_feeVault != address(0) && _feeVault != address(this), InvalidFeeVault());
        feeVault = _feeVault;
        emit FeeVaultSet(_feeVault);
    }

    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), ZeroAddress());
        verifier = _verifier;
        emit ZapVerifierSet(_verifier);
    }

    function addAdmin(address _account) external onlyOwner {
        admins[_account] = true;
        emit AdminAdded(_account);
    }

    function removeAdmin(address _account) external onlyOwner {
        admins[_account] = false;
        emit AdminRemoved(_account);
    }

    function addReferral(address _referral, uint96 _nativeFeeShare, uint96 _tokenFeeShare) external onlyOwnerOrAdmin {
        require(_referral != address(0), ZeroAddress());
        referralFeeInfo[_referral] = ReferralFeeInfo({ nativeFeeShare: _nativeFeeShare, tokenFeeShare: _tokenFeeShare });
        emit ReferralAdded(_referral);
    }

    function recoverToken(address _token, address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferToken(_token, _recipient, _amount);
        emit TokenRecovered(_token, _recipient, _amount);
    }

    function recoverERC721(address _token, address _recipient, uint256 _id) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferERC721(_token, _recipient, _id);
        emit ERC721Recovered(_token, _recipient, _id);
    }

    function recoverERC1155(address _token, address _recipient, uint256[] calldata _ids, uint256[] calldata _amounts) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferBatchERC1155(_token, _recipient, _ids, _amounts);
        emit ERC1155Recovered(_token, _recipient, _ids, _amounts);
    }

    // -------------EXTERNAL-------------

    function registerAsReferral() external {
        require(referralFeeInfo[msg.sender].nativeFeeShare == 0 || referralFeeInfo[msg.sender].tokenFeeShare == 0, ReferralAlreadyAdded());
        referralFeeInfo[msg.sender] = ReferralFeeInfo({ nativeFeeShare: defaultReferralNativeFeeShare, tokenFeeShare: defaultReferralTokenFeeShare });
        emit ReferralAdded(msg.sender);
    }

    // solhint-disable-next-line code-complexity
    function zap(bytes32 _transactionId, bytes calldata _data, bytes calldata _signature, address _referral, InputErc20Tokens[] calldata _inputTokens, address[] calldata _sweepDust, address _dustReciever) external payable nonReentrant refundExcessNative(_dustReciever) {
        require(_dustReciever != address(0), NoTransferToNullAddress());
        _handleVerification(_transactionId, _referral, _data, _signature);
        _handleErcDeposits(_inputTokens);
        _handleZap(_data, _referral);
        _handleSweepTokens(_sweepDust, _dustReciever);
        emit Zapped(msg.sender, _transactionId);
    }

    // -------------HELPERS-------------

    function _verifySignature(bytes calldata _signature, bytes32 _msgHash) private view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, _msgHash));
        require(ECDSA.recover(digest, _signature) == verifier, UnauthorizedSigner());
    }

    function _getRecipient(OutputToken memory outputToken) private view returns (address) {
        return outputToken.transferType == OutputTransferType.ReceiveAndTransfer ? address(this) : outputToken.recipient;
    }

    function _getTotalAnReferralFeeAmount(uint256 _amount, uint256 _fee, uint256 _referralFee) private pure returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        totalFeeAmount = FullMath.mulDiv(_amount, _fee, _BPS_DENOMINATOR);
        if (_referralFee != 0) referralFeeAmount = FullMath.mulDiv(totalFeeAmount, _referralFee, _BPS_DENOMINATOR);
    }

    function _execute(ZapData memory _zapData) private returns (bool success, bytes memory res) {
        if (_zapData.callData.length != 0) {
            if (_zapData.isDelegateCall) {
                (success, res) = _zapData.callTo.delegatecall(_zapData.callData);
                require(success, CallFailed(res));
            } else {
                (success, res) = _zapData.callTo.call{ value: _zapData.nativeValue }(_zapData.callData);
                require(success, CallFailed(res));
            }
        }
    }

    function _transferNativeFee(uint256 _nativeFee, uint256 _referralNativeFeeShare, uint256 _totalNativeFeeAmount, uint256 _totalReferralNativeFeeAmount, address _referral) private {
        if (_nativeFee != 0) {
            _totalNativeFeeAmount += _nativeFee;
            if (_referralNativeFeeShare != 0) _totalReferralNativeFeeAmount += FullMath.mulDiv(_nativeFee, _referralNativeFeeShare, _BPS_DENOMINATOR);
        }

        if (_totalNativeFeeAmount != 0) {
            LibAsset.transferNativeToken(feeVault, _totalNativeFeeAmount - _totalReferralNativeFeeAmount);
            if (_totalReferralNativeFeeAmount != 0) LibAsset.transferNativeToken(_referral, _totalReferralNativeFeeAmount);
        }
    }

    function _transferTokenFee(address _tokenAddress, address _referralAddress, uint256 _totalFeeAmount, uint256 _referralFeeAmount) private {
        if (_totalFeeAmount != 0) {
            if (_referralFeeAmount != 0) LibAsset.transferERC20(_tokenAddress, _referralAddress, _referralFeeAmount);
            LibAsset.transferERC20(_tokenAddress, feeVault, _totalFeeAmount - _referralFeeAmount);
        }
    }

    function _revokeErc1155Approvals(InputToken[] memory inputTokens) private {
        uint256 inputTokensLength = inputTokens.length;
        for (uint256 i = 0; i < inputTokensLength; ++i) {
            if (inputTokens[i].tokenType == TokenType.ERC1155 && inputTokens[i].transferType == InputTransferType.ApproveForSpender) {
                LibAsset.revokeERC1155(inputTokens[i].tokenAddress, inputTokens[i].approveTo);
            }
        }
    }

    function _getOutputTokensInitialBalance(uint256 _calldataLength, uint256 _outputLength, uint256 _nativeValueToTransfer, uint256 _outputCount, OutputToken[] memory _outputTokens) private view returns (uint256[] memory) {
        if (_calldataLength != 0) {
            uint256 outputEndIndex = _outputCount + _outputLength;
            uint256[] memory initialOutputBalances = new uint256[](_outputLength);
            uint256 index;
            for (uint256 i = _outputCount; i < outputEndIndex; ++i) {
                OutputToken memory outputToken = _outputTokens[i];
                address recipient = _getRecipient(outputToken);

                if (outputToken.tokenType == TokenType.ERC20) {
                    initialOutputBalances[index++] = LibAsset.getErc20Balance(outputToken.tokenAddress, recipient);
                } else if (outputToken.tokenType == TokenType.NATIVE) {
                    initialOutputBalances[index++] = recipient == address(this) ? LibAsset.selfNativeBalance() - _nativeValueToTransfer : LibAsset.getNativeBalance(recipient);
                } else if (outputToken.tokenType == TokenType.ERC1155) {
                    initialOutputBalances[index++] = LibAsset.getBalanceOfERC1155(outputToken.tokenAddress, recipient, outputToken.tokenId);
                }
            }

            return initialOutputBalances;
        }
    }

    // -------------TOKEN_HANDLERS-------------

    function _handleNativeInput(InputToken memory _inputToken, uint256 _tokenFee, uint256 _referralFee) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        if (_tokenFee != 0) (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(_inputToken.amount, _tokenFee, _referralFee);
        if (_inputToken.transferType == InputTransferType.TransferToSpender) LibAsset.transferNativeToken(_inputToken.approveTo, _inputToken.amount - totalFeeAmount);
    }

    function _handleErc20Input(InputToken memory _inputToken, uint256 _tokenFee, uint256 _referralFee, address _referralAddress) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        if (_tokenFee != 0) (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(_inputToken.amount, _tokenFee, _referralFee);
        uint256 amount = _inputToken.amount - totalFeeAmount;

        if (_inputToken.transferType == InputTransferType.ApproveForSpender) LibAsset.approveERC20(_inputToken.tokenAddress, _inputToken.approveTo, amount);
        else if (_inputToken.transferType == InputTransferType.TransferToSpender) LibAsset.transferERC20(_inputToken.tokenAddress, _inputToken.approveTo, amount);
        
        _transferTokenFee(_inputToken.tokenAddress, _referralAddress, totalFeeAmount, referralFeeAmount);
    }

    function _handleErc721Input(InputToken memory _inputToken) private {
        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            if (LibAsset.getOwnerOfERC721(_inputToken.tokenAddress, _inputToken.tokenId) != address(this)) LibAsset.transferERC721(_inputToken.tokenAddress, msg.sender, address(this), _inputToken.tokenId);
            LibAsset.approveERC721(_inputToken.tokenAddress, _inputToken.approveTo, _inputToken.tokenId);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) LibAsset.transferERC721(_inputToken.tokenAddress, _inputToken.approveTo, _inputToken.tokenId);
        else if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) LibAsset.transferERC721(_inputToken.tokenAddress, msg.sender, _inputToken.approveTo, _inputToken.tokenId);
    }

    function _handleErc1155Input(InputToken memory _inputToken) private {
        if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) {
            LibAsset.transferERC1155(_inputToken.tokenAddress, msg.sender, _inputToken.approveTo, _inputToken.tokenId, _inputToken.amount);
            return;
        }

        uint256 balance = LibAsset.getBalanceOfERC1155(_inputToken.tokenAddress, address(this), _inputToken.tokenId);
        if (balance < _inputToken.amount) LibAsset.transferERC1155(_inputToken.tokenAddress, msg.sender, address(this), _inputToken.tokenId, _inputToken.amount - balance);

        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            LibAsset.approveERC1155(_inputToken.tokenAddress, _inputToken.approveTo);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) LibAsset.transferERC1155(_inputToken.tokenAddress, address(this), _inputToken.approveTo, _inputToken.tokenId, _inputToken.amount);
    }

    function _handleERC20Output(OutputToken memory _outputToken, address _recipient, uint256 _initialBalance, uint256 _tokenFee, uint256 _referralFee, address _referralAddress) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        uint256 returnAmount = LibAsset.getBalance(_outputToken.tokenAddress, _recipient) - _initialBalance;
        require(returnAmount >= _outputToken.minReturn, InvalidReturnAmount(returnAmount, _outputToken.minReturn));

        if (_tokenFee != 0) {
            require(_outputToken.transferType != OutputTransferType.DirectTransferToRecipient, InvalidOutputType());
            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(returnAmount, _tokenFee, _referralFee);
        }
        uint256 amount = returnAmount - totalFeeAmount;

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) LibAsset.transferERC20(_outputToken.tokenAddress, _outputToken.recipient, amount);

        _transferTokenFee(_outputToken.tokenAddress, _referralAddress, totalFeeAmount, referralFeeAmount);
    }

    function _handleNativeOutput(OutputToken memory _outputToken, address _recipient, uint256 _initialBalance, uint256 _tokenFee, uint256 _referralFee) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        uint256 returnAmount = LibAsset.getBalance(_outputToken.tokenAddress, _recipient) - _initialBalance;
        require(returnAmount >= _outputToken.minReturn, InvalidReturnAmount(returnAmount, _outputToken.minReturn));

        if (_tokenFee != 0) {
            require(_outputToken.transferType != OutputTransferType.DirectTransferToRecipient, InvalidOutputType());
            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(returnAmount, _tokenFee, _referralFee);
        }
        
        uint256 amount = returnAmount - totalFeeAmount;
        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) LibAsset.transferNativeToken(_outputToken.recipient, amount);
    }

    function _handleERC721Output(OutputToken memory _outputToken, address _recipient) private {
        require(_recipient == LibAsset.getOwnerOfERC721(_outputToken.tokenAddress, _outputToken.tokenId), InvalidTokenOwner(_outputToken.tokenId));
        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) LibAsset.transferERC721(_outputToken.tokenAddress, _outputToken.recipient, _outputToken.tokenId);
    }

    function _handleERC1155Output(OutputToken memory _outputToken, address _recipient, uint256 _initialBalance) private {
        uint256 returnAmount = LibAsset.getBalanceOfERC1155(_outputToken.tokenAddress, _recipient, _outputToken.tokenId) - _initialBalance;

        require(returnAmount >= _outputToken.minReturn, InvalidReturnAmount(returnAmount, _outputToken.minReturn));
        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) LibAsset.transferERC1155(_outputToken.tokenAddress, address(this), _outputToken.recipient, _outputToken.tokenId, returnAmount);
    }

    function _processInputTokens(address _referral, uint256 _inputCount, ZapData memory _zapData, InputToken[] memory _inputTokens, ReferralFeeInfo memory _referralFee) private returns (uint256 totalNativeFeeAmount, uint256 totalReferralNativeFeeAmount) {
        uint256 length = _inputCount + _zapData.inputLength;
        for (uint256 i = _inputCount; i < length; ++i) {
            InputToken memory inputToken = _inputTokens[i];

            if (inputToken.tokenType == TokenType.NATIVE) {
                (uint256 totalFeeAmount, uint256 referralFeeAmount) = _handleNativeInput(inputToken, inputToken.fee, _referralFee.tokenFeeShare);

                totalNativeFeeAmount += totalFeeAmount;
                totalReferralNativeFeeAmount += referralFeeAmount;
            } else if (inputToken.tokenType == TokenType.ERC20) _handleErc20Input(inputToken, inputToken.fee, _referralFee.tokenFeeShare, _referral);
            else if (inputToken.tokenType == TokenType.ERC721) _handleErc721Input(inputToken);
            else if (inputToken.tokenType == TokenType.ERC1155) _handleErc1155Input(inputToken);
        }
    }

    function _processOutputTokens(address _referral, uint256 _outputCount, ZapData memory _zapData, OutputToken[] memory _outputTokens, ReferralFeeInfo memory _referralFee, uint256[] memory _initialOutputBalances) private returns (uint256 totalNativeFeeAmount, uint256 totalReferralNativeFeeAmount) {
        uint256 length = _outputCount + _zapData.outputLength;
        uint256 index;
        for (uint256 i = _outputCount; i < length; ++i) {
            OutputToken memory outputToken = _outputTokens[i];
            address recipient = _getRecipient(outputToken);

            if (outputToken.tokenType == TokenType.ERC20) _handleERC20Output(outputToken, recipient, _initialOutputBalances[index++], outputToken.fee, _referralFee.tokenFeeShare, _referral);
            else if (outputToken.tokenType == TokenType.NATIVE) {
                (uint256 totalFeeAmount, uint256 referralFeeAmount) = _handleNativeOutput(outputToken, recipient, _initialOutputBalances[index++], outputToken.fee, _referralFee.tokenFeeShare);

                totalNativeFeeAmount += totalFeeAmount;
                totalReferralNativeFeeAmount += referralFeeAmount;
            } else if (outputToken.tokenType == TokenType.ERC721) _handleERC721Output(outputToken, recipient);
            else if (outputToken.tokenType == TokenType.ERC1155) _handleERC1155Output(outputToken, recipient, _initialOutputBalances[index++]);
        }
    }

    // -------------PRIVATE-------------

    function _handleVerification(bytes32 _transactionId, address _referral, bytes calldata _data, bytes calldata _signature) private {
        bytes32 msgHash = keccak256(abi.encode(_SIGNED_DATA_TYPEHASH, _transactionId, msg.sender, _referral, nonce[msg.sender], keccak256(_data)));
        _verifySignature(_signature, msgHash);
        ++nonce[msg.sender];
    }

    function _handleErcDeposits(InputErc20Tokens[] calldata _inputTokens) private {
        uint256 length = _inputTokens.length;

        for (uint256 i; i < length; ++i) {
            LibAsset.depositErc20(permit2, _inputTokens[i].token, msg.sender, address(this), _inputTokens[i].amount, _inputTokens[i].permit);
        }
    }

    function _handleSweepTokens(address[] calldata _sweepErc20, address _dustReciever) internal {
        uint256 length = _sweepErc20.length;
        for (uint256 i = 0; i < length; ++i) {
            address tokenAddress = _sweepErc20[i];
            uint256 balance = LibAsset.getBalance(tokenAddress, address(this));
            if (balance != 0) LibAsset.transferERC20(tokenAddress, _dustReciever, balance);
        }
    }

    function _handleZap(bytes calldata _data, address _referral) private {
        (InputToken[] memory inputTokens, OutputToken[] memory outputTokens, ZapData[] memory zapData, uint256 nativeFee) = abi.decode(_data, (InputToken[], OutputToken[], ZapData[], uint256));

        ReferralFeeInfo memory referralFee = referralFeeInfo[_referral];
        uint256 totalReferralNativeFeeAmount;
        uint256 totalNativeFeeAmount;
        uint256 inputCount;
        uint256 outputCount;
        uint256 length = zapData.length;

        for (uint256 i; i < length; ++i) {
            (uint256 nativeFeeAmount, uint256 referralNativeFeeAmount) = _processInputTokens(_referral, inputCount, zapData[i], inputTokens, referralFee);
            inputCount += zapData[i].inputLength;
            totalNativeFeeAmount += nativeFeeAmount;
            totalReferralNativeFeeAmount += referralNativeFeeAmount;

            uint256[] memory initialOutputBalances = _getOutputTokensInitialBalance(zapData[i].callData.length, zapData[i].outputLength, zapData[i].nativeValue, outputCount, outputTokens);

            _execute(zapData[i]);

            (nativeFeeAmount, referralNativeFeeAmount) = _processOutputTokens(_referral, outputCount, zapData[i], outputTokens, referralFee, initialOutputBalances);

            outputCount += zapData[i].outputLength;
            totalNativeFeeAmount += nativeFeeAmount;
            totalReferralNativeFeeAmount += referralNativeFeeAmount;
        }
        require(inputCount == inputTokens.length, InvalidInputLength());
        require(outputCount == outputTokens.length, InvalidOutputLength());

        _revokeErc1155Approvals(inputTokens);
        _transferNativeFee(nativeFee, referralFee.nativeFeeShare, totalNativeFeeAmount, totalReferralNativeFeeAmount, _referral);
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
