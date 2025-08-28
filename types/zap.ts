export enum TokenType {
  UNDEFINED,
  NATIVE,
  ERC20,
  ERC721,
  ERC1155,
}

export enum InputTransferType {
  None,
  ApproveForSpender,
  TransferToSpender,
  DirectTransferToSpender,
  ApproveForSpenderViaPermit2,
}

export enum OutputTransferType {
  ReceiveInContract,
  ReceiveAndTransfer,
  DirectTransferToRecipient,
}

export interface ExecutorFee {
  token: string
  amount: bigint
}

export interface Fees {
  token: string
  integratorFeeAmount: bigint
  protocolFeeAmount: bigint
}

export interface DZapFeeData {
  integrator: string
  fees: Fees[]
}

export interface InputToken {
  tokenType: TokenType
  transferType: InputTransferType
  tokenAddress: string
  amount: bigint
  tokenId: bigint
}

export interface OutputToken {
  tokenType: TokenType
  transferType: OutputTransferType
  tokenAddress: string
  recipient: string
  feeAmount: bigint
  minReturn: bigint
  tokenId: bigint
}

export interface ZapData {
  callTo: string
  approveTo: string
  callData: string
  isDelegateCall: boolean
  nativeValue: bigint
  inputTokens: InputToken[]
  outputTokens: OutputToken[]
}

export interface ZapDeploymentArgs {
  owner: string
  protocolFeeVault: string
  zapVerifier: string
  permit2: string
  uniswapPermit2: string
  uniswapPermit2BytecodeHash: string
  salt: string
}

export interface DepositErc20Tokens {
  token: string
  amount: bigint
  permit: string
}
