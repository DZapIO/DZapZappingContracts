import {
  DEPLOYMENT_CONFIG,
  STAGING_DEPLOYMENT_CONFIG,
} from '../config/deployment'
import { ENVIRONMENT } from '../types'

export const isProd = () => {
  return process.env.NODE_ENV == ENVIRONMENT.PRODUCTION
}

export const getDeploymentConfig = () => {
  return isProd() ? DEPLOYMENT_CONFIG : STAGING_DEPLOYMENT_CONFIG
}
