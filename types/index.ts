import { CHAIN_IDS } from '../config'

export enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

export enum PermitType {
  PERMIT,
  PERMIT2,
}

export enum ApiType {
  ETHERSCAN_V1,
  ETHERSCAN_V2,
  BLOCKSCOUT,
  SOURCIFY,
  OTHER,
}

export interface DzapSwapData {
  callTo: string
  approveTo: string
  from: string
  to: string
  fromAmount: BigInt
  minToAmount: BigInt
  swapCallData: string
  permit: string
}

// Step 2: Define the interface for the inner objects
export interface FacetCut {
  name: string
  action: FacetCutAction
}

// Step 3: Define the interface for the main object with dynamic keys
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
