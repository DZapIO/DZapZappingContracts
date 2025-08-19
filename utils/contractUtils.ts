import { ContractFactory, formatUnits, keccak256, Provider } from 'ethers'
import { ethers } from 'hardhat'

export const getGasPrice = async (
  provider: Provider,
  extraFeePercent = 2.5
  // extraFeePercent = 5 // 5% extra
) => {
  const { gasPrice } = await provider.getFeeData()

  if (gasPrice === null) {
    throw new Error('Could not get gasPrice')
  }

  const newGasPrice =
    gasPrice + (gasPrice * BigInt(extraFeePercent * 10)) / 1000n
  console.log(
    'Gas Price:',
    formatUnits(gasPrice, 'gwei'),
    formatUnits(newGasPrice, 'gwei')
  )
  return newGasPrice
}

export const estimateDeploymentCost = async (
  factory: ContractFactory,
  provider: Provider,
  constructorArgs: any[] = []
) => {
  const deployTransaction = await factory.getDeployTransaction(
    ...constructorArgs
  )

  try {
    const gasEstimate = await provider.estimateGas(deployTransaction)
    const gasPrice = await getGasPrice(provider)
    const deploymentCost = gasEstimate * gasPrice

    console.log('Estimated Gas:', gasEstimate.toString())
    console.log(
      'Estimated Deployment Cost:',
      formatUnits(deploymentCost, 'ether')
    )

    return deploymentCost
  } catch (error) {
    console.error('Error estimating deployment cost:', error)
    return null
  }
}

export const estimateTxCost = async (
  gasEstimate: bigint,
  provider: Provider
) => {
  try {
    // const gasEstimate = await provider.estimateGas(txRequest);
    const { gasPrice } = await provider.getFeeData()

    if (gasPrice === null) {
      throw new Error('Could not get gasPrice')
    }

    const deploymentCost = gasEstimate * gasPrice

    console.log('Estimated Gas:', gasEstimate.toString())
    console.log('Gas Price:', formatUnits(gasPrice, 'gwei'), 'GWEI')
    console.log(
      'Estimated Deployment Cost:',
      formatUnits(deploymentCost, 'ether'),
      'ETH'
    ) // Or other currency

    return deploymentCost
  } catch (error) {
    console.error('Error estimating deployment cost:', error)
    return null
  }
}

export const isContractDeployed = async (contractAddress: string) => {
  const code = await ethers.provider.getCode(contractAddress)
  return code !== '0x'
}

export const getContractBytecodeHash = async (contractAddress: string) => {
  const bytecode = await ethers.provider.getCode(contractAddress)
  return keccak256(bytecode)
}
