import { ethers } from 'hardhat'
import { EXECUTOR_CONFIG, STAGING_EXECUTOR_CONFIG } from '../config/executor'
import { FACTORY_CONFIG, STAGING_FACTORY_CONFIG } from '../config/factory'
import {
  STAGING_WALLET_MANAGER_CONFIG,
  WALLET_MANAGER_CONFIG,
} from '../config/manager'
import { STAGING_ZAP_CONFIG, ZAP_CONFIG } from '../config/zap'
import { CONTRACTS } from '../constants'
import { ChainId, ZapDeploymentArgs } from '../types'
import { getDeploymentConfig, isProd } from './envUtils'
import { PERMIT2_ADDRESS, UNISWAP_PERMIT2 } from '../config'
import { keccak256 } from 'ethers'
import { UNISWAP_EVM_PERMIT2_BYTECODE } from '../config/uniswapPemit2Bytecode'

export const getDeploymentArgs = (chainId: ChainId) => {
  const deploymentConfig = getDeploymentConfig()
  const zapConfig = isProd() ? ZAP_CONFIG : STAGING_ZAP_CONFIG
  const factoryConfig = isProd() ? FACTORY_CONFIG : STAGING_FACTORY_CONFIG
  const managerConfig = isProd()
    ? WALLET_MANAGER_CONFIG
    : STAGING_WALLET_MANAGER_CONFIG
  const executorConfig = isProd() ? EXECUTOR_CONFIG : STAGING_EXECUTOR_CONFIG

  const zapDomainSalt = ethers.id(
    zapConfig.domainSaltKey.replace('<chainId>', chainId.toString())
  )

  const permit2 = PERMIT2_ADDRESS[chainId.toString()]
  const uniswapPermit2 = UNISWAP_PERMIT2.evm
  if (!permit2) {
    throw new Error(
      `Permit2 address not configured for chainId=${chainId.toString()}`
    )
  }

  const zapArgs: ZapDeploymentArgs = {
    owner: zapConfig.owner,
    protocolFeeVault: zapConfig.zapFeeVault,
    zapVerifier: zapConfig.zapVerifier,
    permit2: PERMIT2_ADDRESS[chainId.toString()],
    uniswapPermit2: uniswapPermit2,
    uniswapPermit2BytecodeHash: keccak256(UNISWAP_EVM_PERMIT2_BYTECODE),
    salt: zapDomainSalt,
  }

  const factoryArgs = {
    owner: factoryConfig.owner,
  }

  const walletImpArgs = {
    manager: deploymentConfig.walletManager.contractAddress,
  }

  const managerArgs = {
    owner: managerConfig.owner,
    dZapFactory: deploymentConfig.walletFactory.contractAddress,
    quorum: managerConfig.quorum,
    validatorsToAdd: managerConfig.validators,
  }

  const executorArgs = {
    owner: executorConfig.owner,
    dZapFactory: deploymentConfig.walletFactory.contractAddress,
    executorsToAdd: [
      ...executorConfig.executors,
      deploymentConfig.zap.contractAddress,
    ],
  }

  return {
    [CONTRACTS.DZapZapCore]: {
      address: deploymentConfig.zap.contractAddress,
      constructorArguments: zapArgs,
    },
    [CONTRACTS.DZapWalletFactory]: {
      address: deploymentConfig.walletFactory.contractAddress,
      constructorArguments: factoryArgs,
    },
    [CONTRACTS.DZapWallet]: {
      address: deploymentConfig.walletImp.contractAddress,
      constructorArguments: walletImpArgs,
    },
    [CONTRACTS.DZapWalletManager]: {
      address: deploymentConfig.walletManager.contractAddress,
      constructorArguments: managerArgs,
    },
    [CONTRACTS.DZapExecutor]: {
      address: deploymentConfig.executor.contractAddress,
      constructorArguments: executorArgs,
    },
  }
}
