import { getAddress } from 'ethers'

export const isAddressSame = (addressA: string, addressB: string) => {
  return getAddress(addressA) == getAddress(addressB)
}
