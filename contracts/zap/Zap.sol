// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { LibAsset } from "../shared/libraries/LibAsset.sol";
import { FullMath } from "../shared/libraries/FullMath.sol";

import { IZap } from "../shared/interfaces/IZap.sol";

import { DzapRegistry } from "../shared/DzapRegistry.sol";

import { ZapData, TokenType, InputTransferType, OutputTransferType, InputToken, OutputToken, InputErc20Tokens, ReferralFeeInfo, TokenFeeData } from "./Types.sol";

import { InvalidFeeVault, UnauthorizedCall, CallFailed, InvalidTokenOwner, InvalidReturnAmount, ZeroAddress, InvalidInputLength, InvalidOutputLength, FeeTokenMismatched, ReferralAlreadyAdded, FeeTokenMismatched, ReferralAlreadyAdded, InvalidOutputType, NoTransferToNullAddress } from "../shared/Errors.sol";

contract Zap is Ownable, ERC721Holder, ERC1155Holder, ReentrancyGuard, IZap {
    // -------------STATE-------------

    DzapRegistry public registry;

    address public feeVault;
    address public permit2;
    address public feeVerifier;
    uint96 public defaultReferralNativeFeeShare;
    uint96 public defaultReferralTokenFeeShare;

    bytes32 private immutable _DOMAIN_SEPARATOR;

    uint256 private constant _BPS_DENOMINATOR = 1e6; // 4 basis points
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 private constant _SIGNED_FEE_DATA_TYPEHASH =
        keccak256("SignedFeeData(bytes32 txId,address user,address referral,uint256 nonce,bytes data)");

    mapping(address => ReferralFeeInfo) public referralFeeInfo;
    mapping(address => uint256) public nonce;

    // -------------MODIFIERS-------------

    modifier refundExcessNative(address _refundee) {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        uint256 finalBalance = address(this).balance;

        if (finalBalance > initialBalance) LibAsset.transferNativeToken(_refundee, finalBalance - initialBalance);
    }

    // -------------CONSTRUCTORS-------------

    constructor(
        address _owner,
        address _registry,
        address _feeVault,
        address _permit2,
        bytes32 _salt // chain + dzapVerifier + version
    ) Ownable(_owner) {
        require(_registry != address(0) && _permit2 != address(0), ZeroAddress());
        require(_feeVault != address(0) && _feeVault != address(this), InvalidFeeVault());

        registry = DzapRegistry(_registry);

        feeVault = _feeVault;
        permit2 = _permit2;

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256(bytes("DZapVerifier")), // Contract Name
                keccak256(bytes("1")), // Version
                block.chainid,
                address(this),
                _salt
            )
        );
    }

    // -------------RESTRICTED-------------

    function setFeeVault(address _feeVault) external onlyOwner {
        require(_feeVault != address(0) && _feeVault != address(this), InvalidFeeVault());

        feeVault = _feeVault;
        emit FeeVaultSet(_feeVault);
    }

    function addReferral(address _referral, uint96 _nativeFeeShare, uint96 _tokenFeeShare) external onlyOwner {
        require(_referral != address(0), ZeroAddress());

        referralFeeInfo[_referral] = ReferralFeeInfo(_nativeFeeShare, _tokenFeeShare);
        emit ReferralAdded(msg.sender);
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

    function recoverERC1155(
        address _token,
        address _recipient,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_recipient != address(0), NoTransferToNullAddress());
        LibAsset.transferBatchERC1155(_token, _recipient, _ids, _amounts);

        emit ERC1155Recovered(_token, _recipient, _ids, _amounts);
    }

    // -------------EXTERNAL-------------

    function registerAsReferral() external {
        require(
            referralFeeInfo[msg.sender].nativeFeeShare == 0 && referralFeeInfo[msg.sender].tokenFeeShare == 0,
            ReferralAlreadyAdded()
        );

        referralFeeInfo[msg.sender] = ReferralFeeInfo(defaultReferralNativeFeeShare, defaultReferralTokenFeeShare);

        emit ReferralAdded(msg.sender);
    }

    // solhint-disable-next-line code-complexity
    function zap(
        bytes32 _transactionId,
        bytes calldata _tokenFeeData,
        bytes calldata _signature,
        address _referral,
        ZapData[] calldata _zapData,
        InputErc20Tokens[] calldata _inputTokens,
        address[] calldata _sweepDust
    ) external payable refundExcessNative(msg.sender) nonReentrant {
        _handleVerification(_transactionId, _tokenFeeData, _signature);
        _handleErcDeposits(_inputTokens);
        _handleZap(_tokenFeeData, _referral, _zapData);
        _handleSweepTokens(_sweepDust);

        emit Zapped(msg.sender, _transactionId);
    }

    // -------------HELPERS-------------

    function _verifySignature(bytes calldata _signature, bytes32 _msgHash) private view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, _msgHash));
        address recoveredAddress = ECDSA.recover(digest, _signature);
        return recoveredAddress == feeVerifier;
    }

    function _getRecipient(OutputToken memory outputToken) private view returns (address) {
        return
            outputToken.transferType == OutputTransferType.ReceiveAndTransfer ? address(this) : outputToken.recipient;
    }

    function _getTotalAnReferralFeeAmount(
        uint256 _amount,
        uint256 _fee,
        uint256 _referralFee
    ) private pure returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        totalFeeAmount = FullMath.mulDiv(_amount, _fee, _BPS_DENOMINATOR);

        if (_referralFee > 0) {
            referralFeeAmount = FullMath.mulDiv(totalFeeAmount, _referralFee, _BPS_DENOMINATOR);
        }
    }

    function _execute(
        bool _isDelegateCall,
        address _callTo,
        bytes memory _callData,
        uint256 _nativeValue
    ) private returns (bool success, bytes memory res) {
        if (_isDelegateCall) {
            (success, res) = _callTo.delegatecall(_callData);
            require(success, CallFailed(res));
        } else {
            (success, res) = _callTo.call{ value: _nativeValue }(_callData);
            require(success, CallFailed(res));
        }
    }

    function _transferNativeFee(
        uint256 _nativeFee,
        uint256 _referralNativeFeeShare,
        uint256 _totalNativeFeeAmount,
        uint256 _totalReferralNativeFeeAmount,
        address _referral
    ) private {
        if (_nativeFee > 0) {
            _totalNativeFeeAmount += _nativeFee;
            if (_referralNativeFeeShare > 0) {
                _totalReferralNativeFeeAmount += FullMath.mulDiv(_nativeFee, _referralNativeFeeShare, _BPS_DENOMINATOR);
            }
        }

        if (_totalNativeFeeAmount > 0) {
            LibAsset.transferNativeToken(feeVault, _totalNativeFeeAmount - _totalReferralNativeFeeAmount);
            if (_totalReferralNativeFeeAmount > 0)
                LibAsset.transferNativeToken(_referral, _totalReferralNativeFeeAmount);
        }
    }

    function _transferTokenFee(
        address _tokenAddress,
        address _referralAddress,
        uint256 _totalFeeAmount,
        uint256 _referralFeeAmount
    ) private {
        if (_totalFeeAmount > 0) {
            if (_referralFeeAmount > 0) {
                LibAsset.transferERC20(_tokenAddress, _referralAddress, _referralFeeAmount);
            }
            LibAsset.transferERC20(_tokenAddress, feeVault, _totalFeeAmount - _referralFeeAmount);
        }
    }

    function _revokeErc1155Approvals(InputToken[] calldata inputTokens) private {
        for (uint256 j = 0; j < inputTokens.length; ++j) {
            if (inputTokens[j].transferType == InputTransferType.ApproveForSpender) {
                LibAsset.revokeERC1155(inputTokens[j].tokenAddress, inputTokens[j].approveTo);
            }
        }
    }

    // -------------TOKEN_HANDLERS-------------

    function _handleNativeInput(
        InputToken memory _inputToken,
        uint256 _tokenFee,
        uint256 _referralFee
    ) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        if (_tokenFee > 0) {
            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(
                _inputToken.amount,
                _tokenFee,
                _referralFee
            );
        }
        if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferNativeToken(_inputToken.approveTo, _inputToken.amount - totalFeeAmount);
        }
    }

    function _handleErc20Input(
        InputToken memory _inputToken,
        uint256 _tokenFee,
        uint256 _referralFee,
        address _referralAddress
    ) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        if (_tokenFee > 0) {
            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(
                _inputToken.amount,
                _tokenFee,
                _referralFee
            );
        }
        uint256 amount = _inputToken.amount - totalFeeAmount;

        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            LibAsset.approveERC20(_inputToken.tokenAddress, _inputToken.approveTo, amount);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferERC20(_inputToken.tokenAddress, _inputToken.approveTo, amount);
        }
        // DirectTransferToSpender is not need here

        // transfer token fee
        _transferTokenFee(_inputToken.tokenAddress, _referralAddress, totalFeeAmount, referralFeeAmount);
    }

    function _handleErc721Input(InputToken memory _inputToken) private {
        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            if (LibAsset.getOwnerOfERC721(_inputToken.tokenAddress, _inputToken.tokenId) != address(this)) {
                LibAsset.transferERC721(_inputToken.tokenAddress, msg.sender, address(this), _inputToken.tokenId);
            }

            LibAsset.approveERC721(_inputToken.tokenAddress, _inputToken.approveTo, _inputToken.tokenId);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferERC721(_inputToken.tokenAddress, _inputToken.approveTo, _inputToken.tokenId);
        } else if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) {
            LibAsset.transferERC721(_inputToken.tokenAddress, msg.sender, _inputToken.approveTo, _inputToken.tokenId);
        }
    }

    function _handleErc1155Input(InputToken memory _inputToken) private {
        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            uint256 balance = LibAsset.getBalanceOfERC1155(
                _inputToken.tokenAddress,
                address(this),
                _inputToken.tokenId
            );
            if (balance < _inputToken.amount) {
                LibAsset.transferERC1155(
                    _inputToken.tokenAddress,
                    msg.sender,
                    address(this),
                    _inputToken.tokenId,
                    _inputToken.amount - balance
                );
            }

            // remember to make if false after call
            LibAsset.approveERC1155(_inputToken.tokenAddress, _inputToken.approveTo);
        } else if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) {
            LibAsset.transferERC1155(
                _inputToken.tokenAddress,
                msg.sender,
                _inputToken.approveTo,
                _inputToken.tokenId,
                _inputToken.amount
            );
        }
    }

    function _handleERC20Output(
        OutputToken memory _outputToken,
        address recipient,
        uint256 initialBalance,
        uint256 _tokenFee,
        uint256 _referralFee,
        address _referralAddress
    ) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        uint256 returnAmount = LibAsset.getBalance(_outputToken.tokenAddress, recipient) - initialBalance;

        require(returnAmount >= _outputToken.minReturn, InvalidReturnAmount(returnAmount, _outputToken.minReturn));

        if (_tokenFee > 0) {
            require(_outputToken.transferType != OutputTransferType.DirectTransferToRecipient, InvalidOutputType());

            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(returnAmount, _tokenFee, _referralFee);
        }
        uint256 amount = returnAmount - totalFeeAmount;

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferERC20(_outputToken.tokenAddress, _outputToken.recipient, amount);
        }

        // transfer token fee
        _transferTokenFee(_outputToken.tokenAddress, _referralAddress, totalFeeAmount, referralFeeAmount);
    }

    function _handleNativeOutput(
        OutputToken memory _outputToken,
        address recipient,
        uint256 initialBalance,
        uint256 _tokenFee,
        uint256 _referralFee
    ) private returns (uint256 totalFeeAmount, uint256 referralFeeAmount) {
        uint256 returnAmount = LibAsset.getBalance(_outputToken.tokenAddress, recipient) - initialBalance;

        require(returnAmount >= _outputToken.minReturn, InvalidReturnAmount(returnAmount, _outputToken.minReturn));

        if (_tokenFee > 0) {
            require(_outputToken.transferType != OutputTransferType.DirectTransferToRecipient, InvalidOutputType());

            (totalFeeAmount, referralFeeAmount) = _getTotalAnReferralFeeAmount(returnAmount, _tokenFee, _referralFee);
        }
        uint256 amount = returnAmount - totalFeeAmount;

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferNativeToken(_outputToken.recipient, amount);
        }
    }

    function _handleERC721Output(OutputToken memory outputToken, address recipient) private {
        if (outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferERC721(outputToken.tokenAddress, recipient, outputToken.tokenId);
        } else if (outputToken.transferType == OutputTransferType.DirectTransferToRecipient) {
            require(
                recipient == LibAsset.getOwnerOfERC721(outputToken.tokenAddress, outputToken.tokenId),
                InvalidTokenOwner(outputToken.tokenId)
            );
        }
    }

    function _handleERC1155Output(OutputToken memory outputToken, address recipient, uint256 initialBalance) private {
        uint256 returnAmount = LibAsset.getBalanceOfERC1155(
            outputToken.tokenAddress,
            address(this),
            outputToken.tokenId
        ) - initialBalance;

        require(returnAmount >= outputToken.minReturn, InvalidReturnAmount(returnAmount, outputToken.minReturn));

        if (outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferERC1155(
                outputToken.tokenAddress,
                address(this),
                recipient,
                outputToken.tokenId,
                returnAmount
            );
        }
    }

    function _processInputTokens(
        address _referral,
        uint256 inputCount,
        ZapData calldata zapData,
        ReferralFeeInfo memory referralFee,
        TokenFeeData[] memory inputTokenFeeData
    ) private returns (uint256 totalNativeFeeAmount, uint256 totalReferralNativeFeeAmount) {
        for (uint256 j = 0; j < zapData.inputTokens.length; ++j) {
            InputToken memory inputToken = zapData.inputTokens[j];
            TokenFeeData memory feeData = inputTokenFeeData[inputCount + j];
            require(feeData.tokenAddress == inputToken.tokenAddress, FeeTokenMismatched());

            if (inputToken.tokenType == TokenType.NATIVE) {
                (uint256 totalFeeAmount, uint256 referralFeeAmount) = _handleNativeInput(
                    inputToken,
                    feeData.fee,
                    referralFee.tokenFeeShare
                );

                totalNativeFeeAmount += totalFeeAmount;
                totalReferralNativeFeeAmount += referralFeeAmount;
            } else if (inputToken.tokenType == TokenType.ERC20) {
                _handleErc20Input(inputToken, feeData.fee, referralFee.tokenFeeShare, _referral);
            } else if (inputToken.tokenType == TokenType.ERC721) {
                _handleErc721Input(inputToken);
            } else if (inputToken.tokenType == TokenType.ERC1155) {
                _handleErc1155Input(inputToken);
            }
        }
    }

    function _processOutputTokens(
        address _referral,
        uint256 outputCount,
        ZapData calldata zapData,
        ReferralFeeInfo memory referralFee,
        TokenFeeData[] memory outputTokenFeeData,
        uint256[] memory initialOutputBalances
    ) private returns (uint256 totalNativeFeeAmount, uint256 totalReferralNativeFeeAmount) {
        for (uint256 j = 0; j < zapData.outputTokens.length; ++j) {
            OutputToken memory outputToken = zapData.outputTokens[j];
            TokenFeeData memory feeData = outputTokenFeeData[outputCount + j];

            require(feeData.tokenAddress == outputToken.tokenAddress, FeeTokenMismatched());
            address recipient = _getRecipient(outputToken);

            if (outputToken.tokenType == TokenType.ERC20) {
                _handleERC20Output(
                    outputToken,
                    recipient,
                    initialOutputBalances[j],
                    feeData.fee,
                    referralFee.tokenFeeShare,
                    _referral
                );
            } else if (outputToken.tokenType == TokenType.NATIVE) {
                (uint256 totalFeeAmount, uint256 referralFeeAmount) = _handleNativeOutput(
                    outputToken,
                    recipient,
                    initialOutputBalances[j],
                    feeData.fee,
                    referralFee.tokenFeeShare
                );

                totalNativeFeeAmount += totalFeeAmount;
                totalReferralNativeFeeAmount += referralFeeAmount;
            } else if (outputToken.tokenType == TokenType.ERC721) {
                _handleERC721Output(outputToken, recipient);
            } else if (outputToken.tokenType == TokenType.ERC1155) {
                _handleERC1155Output(outputToken, recipient, initialOutputBalances[j]);
            }
        }
    }

    // -------------PRIVATE-------------

    function _handleVerification(bytes32 _transactionId, bytes calldata _data, bytes calldata _signature) private {
        bytes32 msgHash = keccak256(
            abi.encode(_SIGNED_FEE_DATA_TYPEHASH, msg.sender, _transactionId, nonce[msg.sender], keccak256(_data))
        );

        _verifySignature(_signature, msgHash);

        nonce[msg.sender]++;
    }

    function _handleErcDeposits(InputErc20Tokens[] calldata _inputTokens) private {
        uint256 length = _inputTokens.length;

        for (uint256 i; i < length; i++) {
            LibAsset.depositErc20(
                permit2,
                _inputTokens[i].token,
                msg.sender,
                address(this),
                _inputTokens[i].amount,
                _inputTokens[i].permit
            );
        }
    }

    function _handleSweepTokens(address[] calldata _sweepErc20) internal {
        uint256 length = _sweepErc20.length;
        for (uint256 i = 0; i < length; ++i) {
            address tokenAddress = _sweepErc20[i];
            uint256 balance = LibAsset.getBalance(tokenAddress, address(this));
            if (balance > 0) LibAsset.transferERC20(tokenAddress, msg.sender, balance);
        }
    }

    function _handleZap(bytes calldata _tokenFeeData, address _referral, ZapData[] calldata _zapData) private {
        (TokenFeeData[] memory inputTokenFeeData, TokenFeeData[] memory outputTokenFeeData, uint256 nativeFee) = abi
            .decode(_tokenFeeData, (TokenFeeData[], TokenFeeData[], uint256));

        ReferralFeeInfo memory referralFee = referralFeeInfo[_referral];
        uint256 totalReferralNativeFeeAmount;
        uint256 totalNativeFeeAmount;
        uint256 inputCount;
        uint256 outputCount;
        uint256 length = _zapData.length;

        for (uint256 i; i < length; i++) {
            // ZapData memory zapData = _zapData[i];

            uint256 inputTokenLength = _zapData[i].inputTokens.length;
            uint256 outputTokenLength = _zapData[i].outputTokens.length;
            uint256[] memory initialOutputBalances = new uint256[](outputTokenLength);

            (uint256 nativeFeeAmount, uint256 referralNativeFeeAmount) = _processInputTokens(
                _referral,
                inputCount,
                _zapData[i],
                referralFee,
                inputTokenFeeData
            );
            inputCount += inputTokenLength;
            totalNativeFeeAmount += nativeFeeAmount;
            totalReferralNativeFeeAmount += referralNativeFeeAmount;

            if (_zapData[i].callData.length > 0) {
                require(registry.isTargetWhitelisted(_zapData[i].callTo), UnauthorizedCall(_zapData[i].callTo));

                for (uint256 j = 0; j < outputTokenLength; ++j) {
                    OutputToken memory outputToken = _zapData[i].outputTokens[j];

                    address recipient = _getRecipient(outputToken);

                    if (outputToken.tokenType == TokenType.ERC20) {
                        initialOutputBalances[j] = LibAsset.getBalance(outputToken.tokenAddress, recipient);
                    } else if (outputToken.tokenType == TokenType.ERC1155) {
                        initialOutputBalances[j] = LibAsset.getBalanceOfERC1155(
                            outputToken.tokenAddress,
                            recipient,
                            outputToken.tokenId
                        );
                    }
                }
            }

            _execute(_zapData[i].isDelegateCall, _zapData[i].callTo, _zapData[i].callData, _zapData[i].nativeValue);

            (nativeFeeAmount, referralNativeFeeAmount) = _processOutputTokens(
                _referral,
                outputCount,
                _zapData[i],
                referralFee,
                outputTokenFeeData,
                initialOutputBalances
            );
            outputCount += outputTokenLength;
            totalNativeFeeAmount += nativeFeeAmount;
            totalReferralNativeFeeAmount += referralNativeFeeAmount;

            _revokeErc1155Approvals(_zapData[i].inputTokens);
        }

        require(inputCount == inputTokenFeeData.length, InvalidInputLength());
        require(outputCount == outputTokenFeeData.length, InvalidOutputLength());

        _transferNativeFee(
            nativeFee,
            referralFee.nativeFeeShare,
            totalNativeFeeAmount,
            totalReferralNativeFeeAmount,
            _referral
        );
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
