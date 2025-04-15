import { CHAIN_IDS } from '.'

export const DEPLOYMENT_CONFIG = {
  adapters: {
    aerodromeClFarmingAdapter: {
      deployer: '',
      saltKey: '',
      contractAddress: '',
      creationCode: '',
    },
  },
  registry: {
    deployer: '',
    saltKey: '',
    contractAddress: '',
    creationCode: '',
  },
  walletImp: {
    deployer: '',
    saltKey: '',
    contractAddress: '',
    creationCode: '',
  },
  walletFactory: {
    deployer: '',
    saltKey: '',
    contractAddress: '',
    creationCode: '',
  },
  executor: {
    deployer: '',
    saltKey: '',
    contractAddress: '',
    creationCode: '',
  },
  zap: {
    deployer: '',
    saltKey: '',
    contractAddress: '',
    creationCode: '',
  },
}

export const STAGING_DEPLOYMENT_CONFIG = {
  adapters: {
    AerodromeClFarmingAdapter: {
      deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
      saltKey: 'TestDZapAerodromeClFarmingAdapter',
      contractAddress: '0x6E17Bf8a7f42188a9E125E450C2674648a9d3EA5',
      creationCode: '',
    },
    FluidVaultAdapter: {
      deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
      saltKey: 'TestDZapFluidVaultAdapter03',
      // saltKey: 'TestDZapFluidVaultAdapterV3',
      contractAddress: '0x718F636a788fc77118fba38262903F8E375F9c19',
      // contractAddress: '0x9E734dCd9442aA64bA7578e54553d9AeeEB82A5d',
      creationCode: '',
    },
    DisperseEthAdapter: {
      deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
      saltKey: 'TestDZapDisperseEthAdapter',
      contractAddress: '0xD0b7fe8359D4a5ff76c90B81FF688C3F0Df85f48',
      creationCode: '',
    },
  },
  registry: {
    deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
    saltKey: 'TestDZapWalletRegistry',
    contractAddress: '0xC578441Fa4568C201679c3606B71594801Eb7ED4',
    creationCode: '',
  },
  walletImp: {
    deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
    saltKey: 'TestDZapWalletImplementation',
    contractAddress: '0x309158606af94b804b0b9F897b9d8d9169FE52d0',
    creationCode: '',
  },
  walletFactory: {
    deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
    saltKey: 'TestDZapWalletFactory',
    contractAddress: '0xe8168BAeFc6eD5ad1cf2289e458Fd4C75089Ca0f',
    creationCode: '',
  },
  executor: {
    deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
    saltKey: 'TestDZapWalletExecutor',
    contractAddress: '0x0a98f903D6B8e8345b47e955624e042A9FDFE056',
    creationCode: '',
  },
  zap: {
    deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
    // saltKey: 'TestDZapZap2',
    // contractAddress: '0x1d46863e3592745008b5CbbAC12014F67329A9b8',
    // saltKey: 'TestDZapZap1',
    // contractAddress: '0xe4D0E710dd38C5a9B5A325d5e41664ea89C613d0',
    saltKey: 'TestDZapZap',
    contractAddress: '0x1395A2061894AD483855A40Dec3bf9D7fE949c0D',
    creationCode: '',
  },
}

export const ZAP_ADDRESS = {
  staging: {
    [CHAIN_IDS.BASE_MAINNET]: '0x1d46863e3592745008b5CbbAC12014F67329A9b8', // new
    [CHAIN_IDS.ARBITRUM_MAINNET]: '0xe4D0E710dd38C5a9B5A325d5e41664ea89C613d0', // new
    [CHAIN_IDS.OPTIMISM_MAINNET]: '0x1395A2061894AD483855A40Dec3bf9D7fE949c0D', // new
    [CHAIN_IDS.POLYGON_MAINNET]: '0x1d46863e3592745008b5CbbAC12014F67329A9b8', // new
    [CHAIN_IDS.MANTLE_MAINNET]: '0x1d46863e3592745008b5CbbAC12014F67329A9b8',
    [CHAIN_IDS.ETH_MAINNET]: '0x1395A2061894AD483855A40Dec3bf9D7fE949c0D', // new
    [CHAIN_IDS.AVALANCHE_MAINNET]: '0xe4D0E710dd38C5a9B5A325d5e41664ea89C613d0', // new
  },
  production: {},
}
