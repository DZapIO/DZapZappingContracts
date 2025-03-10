import { BPS_MULTIPLIER } from '../constants'

export const ZAP_CONGIG = {
  owner: '',
  zapFeeVault: '',
  zapVerifier: '',
  domainSaltKey: '-<chainId>',
  defaultReferralNativeFeeShare: 0n,
  defaultReferralTokenFeeShare: 0n,
}

export const STAGING_ZAP_CONGIG = {
  owner: '0x12480616436dd6d555f88b8d94bb5156e28825b1',
  zapFeeVault: '0xdbcf663ee23e7887c7d77b8143ddffdd5001c693',
  zapVerifier: '0xdc7cc0c5360d4bd4eb13f563d9bd974e49fdfb53',
  domainSaltKey: 'Test-DZap-v0.1-<chainId>',
  defaultReferralNativeFeeShare: 25n * BPS_MULTIPLIER,
  defaultReferralTokenFeeShare: 30n * BPS_MULTIPLIER,
}
