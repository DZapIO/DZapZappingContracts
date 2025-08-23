import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { BigNumberish, Wallet } from 'ethers'
import { DZapFeeData, ExecutorFee, ZapData } from './zap'
import { MockERC20, Permit2 } from '../typechain-types'

// ------------------

export interface PermitDetails {
  token: string
  amount: BigNumberish
  expiration: BigNumberish
  nonce: BigNumberish
}

export interface PermitSingle {
  details: PermitDetails
  spender: string
  sigDeadline: BigNumberish
}

export interface TokenPermissions {
  token: string
  amount: BigNumberish
}

export interface DZapZapWitness {
  txId: string
  user: string
  dustReceiver: string
  zapDataHash: string
  feeDataHash: string
  executorFeeDataHash: string
  crosschainDataHash: string
  sweepDataHash: string
}

export interface SignatureTransferDetails {
  to: string
  requestedAmount: BigNumberish
}

export interface DZapTransferWitness {
  owner: string
  recipient: string
}

export interface PermitBatchTransferFrom {
  permitted: TokenPermissions[]
  nonce: BigNumberish
  deadline: BigNumberish
}

export interface DZapPermit2BatchTransferWitness
  extends PermitBatchTransferFrom {
  spender: string
  witness: DZapTransferWitness
}

export interface PermitTransferFrom {
  permitted: TokenPermissions
  nonce: BigNumberish
  deadline: BigNumberish
}

export interface DZapPermit2TransferWitness extends PermitTransferFrom {
  spender: string
  witness: DZapTransferWitness
}

export interface DZapPermit2BatchZapWitness extends PermitBatchTransferFrom {
  spender: string
  witness: DZapZapWitness
}

// ------------------

export interface ZapSignatureArgs {
  chainId: number
  zapAddress: string
  signer: Wallet | HardhatEthersSigner
  salt?: string
  version?: string

  txId: string
  user: string
  nonce?: number | bigint
  deadline?: bigint
  zapData: ZapData[]
  feeData: DZapFeeData
}

export interface GasLessPermit2ZapWitnessArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  permit2: Permit2
  spender: string
  tokenInfo: TokenPermissions[]

  txId: string
  dustReceiver: string
  crosschainData: string
  nonce?: number | bigint
  deadline?: bigint
  zapData: ZapData[]
  feeData: DZapFeeData
  executorFeeData: ExecutorFee[]
  sweepTokens: string[]
}

export interface GasLessZapSignatureArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  zapAddress: string
  salt?: string
  version?: string

  txId: string
  user: string
  dustReceiver: string
  crosschainData: string
  nonce?: number | bigint
  deadline?: bigint
  zapData: ZapData[]
  feeData: DZapFeeData
  executorFeeData: ExecutorFee[]
  sweepTokens: string[]
}

export interface Eip2612SigArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  token: MockERC20
  spender: string
  amount: BigInt
  deadline?: bigint
  version?: string
  nonce?: BigNumberish
  name?: string
}

export interface Permit2ApproveSigArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  permit2: Permit2
  token: string
  spender: string
  amount: bigint
  sigDeadline?: bigint
  expiration?: bigint
  userNonce?: number | bigint
}

export interface Permit2BatchTransferFromWitnessSigArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  permit2: Permit2
  tokenInfo: TokenPermissions[]
  recipient: string
  spender: string
  deadline?: BigNumberish
  nonce?: BigNumberish
}

export interface Permit2TransferFromWitnessSigArgs {
  chainId: number
  signer: Wallet | HardhatEthersSigner
  permit2: Permit2
  token: string
  recipient: string
  spender: string
  amount: BigNumberish
  deadline?: BigNumberish
  nonce?: BigNumberish
}

// ------------------

export const DZapSignedZapData = [
  { name: 'txId', type: 'bytes32' },
  { name: 'user', type: 'address' },
  { name: 'nonce', type: 'uint256' },
  { name: 'deadline', type: 'uint256' },
  { name: 'zapDataHash', type: 'bytes32' },
  { name: 'feeDataHash', type: 'bytes32' },
]

export const DZapGaslessZapData = [
  { name: 'txId', type: 'bytes32' },
  { name: 'user', type: 'address' },
  { name: 'dustReceiver', type: 'address' },
  { name: 'nonce', type: 'uint256' },
  { name: 'deadline', type: 'uint256' },
  { name: 'zapDataHash', type: 'bytes32' },
  { name: 'feeDataHash', type: 'bytes32' },
  { name: 'executorFeeDataHash', type: 'bytes32' },
  { name: 'crosschainDataHash', type: 'bytes32' },
  { name: 'sweepDataHash', type: 'bytes32' },
]

export const PermitTypes = [
  {
    name: 'owner',
    type: 'address',
  },
  {
    name: 'spender',
    type: 'address',
  },
  {
    name: 'value',
    type: 'uint256',
  },
  {
    name: 'nonce',
    type: 'uint256',
  },
  {
    name: 'deadline',
    type: 'uint256',
  },
]

export const Permit2Types = {
  PermitSingle: [
    { name: 'details', type: 'PermitDetails' },
    { name: 'spender', type: 'address' },
    { name: 'sigDeadline', type: 'uint256' },
  ],
  PermitDetails: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint160' },
    { name: 'expiration', type: 'uint48' },
    { name: 'nonce', type: 'uint48' },
  ],
}

export const DZapTransferWitness = {
  DZapTransferWitness: [
    { name: 'owner', type: 'address' },
    { name: 'recipient', type: 'address' },
  ],
}

export const DZapPermitWitnessTransferFromTypes = {
  PermitWitnessTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
    { name: 'witness', type: 'DZapTransferWitness' },
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' },
  ],
  ...DZapTransferWitness,
}

export const DZapPermit2BatchWitnessTransferFromTypes = {
  PermitBatchWitnessTransferFrom: [
    { name: 'permitted', type: 'TokenPermissions[]' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
    { name: 'witness', type: 'DZapTransferWitness' },
  ],
  TokenPermissions: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint256' },
  ],
  ...DZapTransferWitness,
}
