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
    aerodromeClFarmingAdapter: {
      deployer: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
      saltKey: 'TestDZapAerodromeClFarmingAdapter',
      contractAddress: '0x6E17Bf8a7f42188a9E125E450C2674648a9d3EA5',
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
    saltKey: 'TestDZapZap',
    contractAddress: '0x1395A2061894AD483855A40Dec3bf9D7fE949c0D',
    creationCode: '',
  },
}
