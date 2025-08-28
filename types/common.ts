import { CHAIN_IDS } from '../config'
import { NODE_ENV_VAR_NAMES } from '../constants'
import { MockErc1155, MockERC20, MockErc721, WNATIVE } from '../typechain-types'

export enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

export enum ApiType {
  NONE,
  ETHERSCAN_V1,
  ETHERSCAN_V2,
  BLOCKSCOUT,
  SOURCIFY,
  OTHER,
}

export enum PermitType {
  PERMIT, // EIP2612
  PERMIT2_APPROVE,
  PERMIT2_WITNESS_TRANSFER,
  BATCH_PERMIT2_WITNESS_TRANSFER,
}

export interface FacetCut {
  name: string
  action: FacetCutAction
}

export interface FacetCuts {
  [address: string]: FacetCut
}

export interface AccessContractObj {
  [key: string]: {
    executor: string
    functionNames: string[]
  }
}

export interface NativeCurrency {
  name: string
  symbol: string
  decimals: number
}

export interface Network {
  chainId: CHAIN_IDS
  chainName: string
  shortName: string
  rpcUrl: string[]
  explorerUrl: string
  apiUrl?: string
  apiType: ApiType
  apiKeyName?: NODE_ENV_VAR_NAMES
  nativeCurrency: NativeCurrency
}

export type Networks = {
  [key in CHAIN_IDS]?: Network
}

export enum ENVIRONMENT {
  PRODUCTION = 'production',
  STAGING = 'staging',
  DEVELOPMENT = 'development',
}

export interface SelectorInfo {
  function: string
  functionSig: string
  offset: number
}

export type ChainId = CHAIN_IDS | string | number | bigint

export interface VerificationData {
  contractName: string
  contractAddress: string
  constructorArguments: any[] // as structs can be passed as constructor arguments
}

export interface Erc20Token extends MockERC20 {
  address: string
}

export interface WNativeToken extends WNATIVE {
  address: string
}

export interface ERC721Token extends MockErc721 {
  address: string
}

export interface ERC1155Token extends MockErc1155 {
  address: string
}
