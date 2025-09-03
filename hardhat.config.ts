import * as dotenv from 'dotenv'

import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'

import 'hardhat-abi-exporter'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'

import './tasks/accounts'
import './tasks/clean'

import './tasks/accounts'
import './tasks/clean'

dotenv.config()

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
  },
  solidity: {
    compilers: [
      {
        version: '0.8.30',
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
      only: [
        'DZapZapCore',
        'DZapWalletManager',
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
        'DZapWalletManager',
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
}

export default config
