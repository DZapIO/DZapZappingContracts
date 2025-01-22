export const CONTRACTS = {
  MockERC20: 'MockERC20',
  ERC20: '@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20',
  MockErc721: 'MockErc721',
  MockErc1155: 'MockErc1155',
  MockErc721Dex: 'MockErc721Dex',
  MockErc20Dex: 'MockErc20Dex',
  WNATIVE: 'WNATIVE',
  Permit2: 'Permit2',
  Zap: 'Zap',
}

export const ERRORS = {
  OwnableUnauthorizedAccount: 'OwnableUnauthorizedAccount',
  InvalidFeeVault: 'InvalidFeeVault',
  ZeroAddress: 'ZeroAddress',
  UnauthorizedCaller: 'UnauthorizedCaller',
  NoTransferToNullAddress: 'NoTransferToNullAddress',
  ReferralAlreadyAdded: 'ReferralAlreadyAdded',
}

export const EVENTS = {
  FeeVaultSet: 'FeeVaultSet',
  ZapVerifierSet: 'ZapVerifierSet',
  AdminAdded: 'AdminAdded',
  AdminRemoved: 'AdminRemoved',
  ReferralAdded: 'ReferralAdded',
  TokenRecovered: 'TokenRecovered',
  ERC721Recovered: 'ERC721Recovered',
  ERC1155Recovered: 'ERC1155Recovered',
  DefaultReferralFeeSet: 'DefaultReferralFeeSet',
}
