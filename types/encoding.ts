export const FEES_ABI_TYPE = `tuple(address token,uint256 integratorFeeAmount,uint256 protocolFeeAmount)`
export const FEE_CONFIG_ABI_TYPE = `tuple(address integrator,${FEES_ABI_TYPE}[] fees)`
export const EXECUTOR_INFO_ABI_TYPE = `tuple(address token,uint256 amount)`
export const EXECUTOR_INFO_ABI_TYPE_ARRAY = `${EXECUTOR_INFO_ABI_TYPE}[]`

export const DZapEip2612EncodingType = [
  'uint256',
  'uint8',
  'bytes32',
  'bytes32',
]

export const Eip2612EncodingType = [
  'address',
  'address',
  'uint256',
  'uint256',
  'uint8',
  'bytes32',
  'bytes32',
]

export const DZapPermit2ApproveEncodingType = [
  'uint48 nonce',
  'uint48 expiration',
  'uint256 sigDeadline',
  'bytes signature',
]

export const Permit2ApproveEncodingType = [
  'address owner',
  'tuple(address token, uint160 amount, uint48 expiration, uint48 nonce) details',
  'address spender',
  'uint256 sigDeadline',
  'bytes signature',
]

export const INPUT_TOKEN_TYPE = `tuple(
    uint8 tokenType,
    uint8 transferType,
    address tokenAddress,
    uint256 amount,
    uint256 tokenId
)`

export const OUTPUT_TOKEN_TYPE = `tuple(
    uint8 tokenType,
    uint8 transferType,
    address tokenAddress,
    address recipient,
    uint96 feeAmount,
    uint256 minReturn,
    uint256 tokenId
)`

export const ZAP_DATA_ABI_TYPE = `tuple(
    address callTo,
    address approveTo,
    bytes callData,
    bool isDelegateCall,
    uint256 nativeValue,
    ${INPUT_TOKEN_TYPE}[] inputTokens,
    ${OUTPUT_TOKEN_TYPE}[] outputTokens
)[]`

export const DZapPermit2BatchWitnessGasLessZapTypes = {
  PermitBatchWitnessTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions[]' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
    { name: 'witness', type: 'DZapGaslessZapWitness' },
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' },
  ],
  DZapGaslessZapWitness: [
    { name: 'txId', type: 'bytes32' },
    { name: 'user', type: 'address' },
    { name: 'dustReceiver', type: 'address' },
    { name: 'zapDataHash', type: 'bytes32' },
    { name: 'feeDataHash', type: 'bytes32' },
    { name: 'executorFeeDataHash', type: 'bytes32' },
    { name: 'crosschainDataHash', type: 'bytes32' },
    { name: 'sweepDataHash', type: 'bytes32' },
  ],
}
