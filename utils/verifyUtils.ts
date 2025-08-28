import { run } from 'hardhat'
import { CHAIN_IDS } from '../config'
import { CONTRACTS_PATH, TASK_VERIFY_SOURCIFY } from '../constants'
import { ApiType, ChainId, VerificationData } from '../types'
import { isContractDeployed } from './contractUtils'
import { getNetwork, toChainId } from './networkUtils'
import { getContractUrl } from './txUtils'

export const verifyContracts = async (
  chainId: ChainId,
  verificationData: VerificationData[]
) => {
  for (const {
    contractName,
    contractAddress,
    constructorArguments,
  } of verificationData) {
    if (await isContractDeployed(contractAddress)) {
      await verify(
        toChainId(chainId),
        contractName,
        contractAddress,
        constructorArguments
      )
    } else {
      console.log(
        `\n\n--------------${contractName} not deployed-------------\n\n`
      )
    }
  }
}

export const verify = async (
  chainId: CHAIN_IDS,
  contractName: string,
  contractAddress: string,
  contractConstructorArguments: any[]
) => {
  const network = getNetwork(chainId)

  if (network.apiType === ApiType.NONE) {
    console.log(
      `\n ${contractName} Verification not supported on ${network.chainName}`,
      getContractUrl(chainId, contractAddress)
    )
    return
  }

  console.log(
    `\n ${contractName} Verification Started...`,
    getContractUrl(chainId, contractAddress)
  )

  try {
    if (network.apiType === ApiType.SOURCIFY) {
      console.log('Sourcify Verification Started...')
      const endpoint = network.apiUrl || 'https://sourcify.dev/server'
      await run(TASK_VERIFY_SOURCIFY, {
        address: contractAddress,
        constructorArguments: contractConstructorArguments,
        endpoint,
      })
      return
    }

    await run('verify:verify', {
      address: contractAddress,
      contract: CONTRACTS_PATH[contractName],
      constructorArguments: contractConstructorArguments,
    })
    console.log(`${contractName} Verification successful...`)
  } catch (error) {
    console.log(error)
    console.log(`${contractName} Verification failed...`)
  }
}
