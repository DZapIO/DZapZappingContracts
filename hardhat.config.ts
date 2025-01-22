import * as dotenv from 'dotenv'

import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'

import 'hardhat-abi-exporter'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'

import './tasks/accounts'
import './tasks/clean'
import { getNetworkConfig, getRpcUrl } from './utils/network'
import { CHAIN_IDS } from './config/networks'

dotenv.config()

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chains: {
        [CHAIN_IDS.BASE_MAINNET]: {
          hardforkHistory: {
            london: 25120000,
          },
        },
      },
    },
    ethereum: getNetworkConfig(CHAIN_IDS.ETH_MAINNET),
    polygon: getNetworkConfig(CHAIN_IDS.POLYGON_MAINNET),
    blast: getNetworkConfig(CHAIN_IDS.BLAST_MAINNET),
    bsc: getNetworkConfig(CHAIN_IDS.BSC_MAINNET),
    arbitrumOne: getNetworkConfig(CHAIN_IDS.ARBITRUM_MAINNET),
    optimism: getNetworkConfig(CHAIN_IDS.OPTIMISM_MAINNET),
    avalanche: getNetworkConfig(CHAIN_IDS.AVALANCHE_MAINNET),
    base: getNetworkConfig(CHAIN_IDS.BASE_MAINNET),
    manta: getNetworkConfig(CHAIN_IDS.MANTA_MAINNET),
    scroll: getNetworkConfig(CHAIN_IDS.SCROLL_MAINNET),
    telos: getNetworkConfig(CHAIN_IDS.TELOS_MAINNET),
    core: getNetworkConfig(CHAIN_IDS.CORE_MAINNET),
    rootstock: getNetworkConfig(CHAIN_IDS.ROOTSTOCK_MAINNET),
    mantle: getNetworkConfig(CHAIN_IDS.MANTLE_MAINNET),
    linea: getNetworkConfig(CHAIN_IDS.LINEA_MAINNET),
    xlayer: getNetworkConfig(CHAIN_IDS.X_LAYER_MAINNET),
    zkSync: getNetworkConfig(CHAIN_IDS.ZKSYNC_MAINNET),
  },
  solidity: {
    compilers: [
      {
        version: '0.8.28',
        settings: {
          optimizer: {
            enabled: true,
            runs: 300,
          },
          viaIR: true,
        },
      },
    ],
  },
  mocha: {
    timeout: 400000,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  abiExporter: [
    {
      runOnCompile: true,
      path: 'data/abi/full',
      only: ['Zap'],
      flat: true,
      clear: true,
    },
    {
      runOnCompile: true,
      path: 'data/abi/pretty',
      format: 'fullName',
      only: ['Zap'],
      flat: true,
      clear: true,
    },
  ],
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      bsc: process.env.BSCSCAN_API_KEY || '',
      polygon: process.env.POLYGONSCAN_API_KEY || '',
      arbitrumOne: process.env.ARBITRUM_API_KEY || '',
      optimisticEthereum: process.env.OPTIMISM_API_KEY || '',
      base: process.env.BASE_API_KEY || '',
      scroll: process.env.SCROLL_API_KEY || '',
      core: process.env.CORE_API_KEY || '',
    },
    customChains: [
      {
        network: 'base',
        chainId: 8453,
        urls: {
          apiURL: 'https://api.basescan.org/api',
          browserURL: 'https://basescan.org/',
        },
      },
      {
        network: 'scroll',
        chainId: 534352,
        urls: {
          apiURL: 'https://api.scrollscan.com/api',
          browserURL: 'https://scrollscan.com/',
        },
      },
      {
        network: 'core',
        chainId: 1116,
        urls: {
          apiURL: 'https://openapi.coredao.org/api',
          browserURL: 'https://scan.coredao.org/',
        },
      },
    ],
  },
}

export default config
