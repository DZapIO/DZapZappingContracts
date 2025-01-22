import { ethers, network } from 'hardhat'

export const BPS_MULTIPLIER = 10000
export const BPS_DENOMINATOR = 100 * BPS_MULTIPLIER
export const ZERO = BigInt(0)
export const HARDHAT_CHAIN_ID = network.config.chainId as number

export const MaxUint48 = BigInt('0xffffffffffff')
export const MaxUint160 = BigInt('0xffffffffffffffffffffffffffffffffffffffff')
export const MaxUint256 = BigInt(
  '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
)
export const MaxSigDeadline = MaxUint256
export const MaxPermit2AllowanceTransferAmount = MaxUint160
export const MaxPermit2AllowanceExpiration = MaxUint48
