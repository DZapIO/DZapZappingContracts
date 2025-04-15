import * as dotenv from 'dotenv'

import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'

import 'hardhat-abi-exporter'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'

import './tasks/accounts'
import './tasks/clean'

import { CHAIN_IDS } from './config/networks'
import './tasks/accounts'
import './tasks/clean'
import {
  getNetworkConfig,
  getRpcUrl,
  getVerificationConfig,
} from './utils/network'

dotenv.config()

const supportedNetworks = [
  CHAIN_IDS.SEPOLIA_TESTNET,
  CHAIN_IDS.HOLESKY_TESTNET,
  CHAIN_IDS.ETH_MAINNET,
  CHAIN_IDS.ARBITRUM_MAINNET,
  CHAIN_IDS.OPTIMISM_MAINNET,
  CHAIN_IDS.ZKSYNC_MAINNET,
  CHAIN_IDS.BASE_MAINNET,
  CHAIN_IDS.POLYGON_MAINNET,
  CHAIN_IDS.BSC_MAINNET,
  CHAIN_IDS.AVALANCHE_MAINNET,
  CHAIN_IDS.MANTA_MAINNET,
  CHAIN_IDS.SCROLL_MAINNET,
  CHAIN_IDS.LINEA_MAINNET,
  CHAIN_IDS.MANTLE_MAINNET,
  CHAIN_IDS.TELOS_MAINNET,
  CHAIN_IDS.CORE_MAINNET,
  CHAIN_IDS.ROOTSTOCK_MAINNET,
  CHAIN_IDS.X_LAYER_MAINNET,
  CHAIN_IDS.POLYGON_ZK_EVM_MAINNET,
  CHAIN_IDS.MODE_MAINNET,
  CHAIN_IDS.METIS_MAINNET,
  CHAIN_IDS.CELO_MAINNET,
  CHAIN_IDS.ZETACHAIN_MAINNET,
  CHAIN_IDS.BLAST_MAINNET,
  CHAIN_IDS.BOBA_ETH,
  CHAIN_IDS.FRAXTAL,
  CHAIN_IDS.GRAVITY,
  CHAIN_IDS.GNOSIS_MAINNET,
  CHAIN_IDS.FUSE,
  CHAIN_IDS.FANTOM_MAINNET,
  CHAIN_IDS.MOONBEAM_MAINNET,
  CHAIN_IDS.MOONRIVER,
  CHAIN_IDS.CRONOS_MAINNET,
  CHAIN_IDS.KAVA_MAINNET,
  CHAIN_IDS.KROMA,
  CHAIN_IDS.AURORA_MAINNET,
  CHAIN_IDS.MINT,
  CHAIN_IDS.ARTHERA,
  CHAIN_IDS.TAIKO_MAINNET,
  CHAIN_IDS.FIRE_MAINNET,
]

const networkConfig = getNetworkConfig(supportedNetworks)
const verificationConfig = getVerificationConfig(supportedNetworks)

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  // defaultNetwork: 'zkMainnet',
  networks: {
    hardhat: {
      accounts: {
        count: 30,
      },
      chains: {
        [CHAIN_IDS.BASE_MAINNET]: {
          hardforkHistory: {
            london: 25120000,
          },
        },
        [CHAIN_IDS.MANTLE_MAINNET]: {
          hardforkHistory: {
            london: 76174808,
          },
        },
        [CHAIN_IDS.POLYGON_MAINNET]: {
          hardforkHistory: {
            london: 69805539,
          },
        },
      },
    },
    ...networkConfig,
    // zkTestnet: {
    //   url: getRpcUrl(CHAIN_IDS.ZKSYNC_SEPOLIA_TESTNET),
    //   ethNetwork: 'sepolia',
    //   zksync: true,
    //   deployPaths: 'scripts/deployZkEVM',
    // },
    // zkMainnet: {
    //   url: getRpcUrl(CHAIN_IDS.ZKSYNC_MAINNET),
    //   ethNetwork: 'mainnet',
    //   zksync: true,
    //   deployPaths: 'scripts/deployZkEVM',
    // },
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
  // zksolc: {
  //   version: 'latest',
  //   compilerSource: 'binary',
  //   settings: {
  //     optimizer: {
  //       enabled: true,
  //       mode: '3',
  //     },
  //   },
  // },
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
      only: [
        'DZapZapCore',
        'DZapRegistry',
        'DZapWalletFactory',
        'DZapWallet',
        'DZapExecutor',
        'AerodromeClFarmingAdapter',
        'FluidVaultAdapter',
      ],
      flat: true,
      clear: true,
    },
    {
      runOnCompile: true,
      path: 'data/abi/pretty',
      format: 'fullName',
      only: [
        'DZapZapCore',
        'DZapRegistry',
        'DZapWalletFactory',
        'DZapWallet',
        'DZapExecutor',
        'AerodromeClFarmingAdapter',
        'FluidVaultAdapter',
      ],
      flat: true,
      clear: true,
    },
  ],
  etherscan: {
    ...verificationConfig.etherscan,
    enabled: true,
  },
  // blockscout: verificationConfig.blockscout,
  // sourcify: {
  //   enabled: true,
  //   // apiUrl: "https://sourcify.dev/server",
  //   // browserUrl: "https://repo.sourcify.dev",
  // },
}

export default config
