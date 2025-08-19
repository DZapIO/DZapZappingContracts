import { formatUnits } from 'ethers'
import { ChainId } from '../types'
import { getNetwork, getProvider } from './networkUtils'

export const getNativeBalance = async (chainId: ChainId, user: string) => {
  const network = getNetwork(chainId)
  const provided = await getProvider(chainId)
  const balanceBn = await provided.getBalance(user)
  const formattedBalance = `${formatUnits(
    balanceBn,
    network.nativeCurrency.decimals
  )} ${network.nativeCurrency.symbol}`

  return {
    balanceBn,
    balance: balanceBn.toString(),
    formattedBalance,
    symbol: network.nativeCurrency.symbol,
  }
}
