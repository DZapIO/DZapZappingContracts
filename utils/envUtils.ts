import {
  DEPLOYMENT_CONFIG,
  STAGING_DEPLOYMENT_CONFIG,
} from '../config/deployment'
import { NODE_ENV_VAR_NAMES } from '../constants'
import { ENVIRONMENT } from '../types'

export const isProd = () => {
  return process.env.NODE_ENV == ENVIRONMENT.PRODUCTION
}

export const getEnvVar = (varName: keyof typeof NODE_ENV_VAR_NAMES) => {
  const envVar = process.env[NODE_ENV_VAR_NAMES[varName]]
  if (!envVar) throw Error(`Environment variable ${varName} is not defined`)
  return envVar
}

export const getDeploymentConfig = () => {
  return isProd() ? DEPLOYMENT_CONFIG : STAGING_DEPLOYMENT_CONFIG
}

export const replaceEnvInStr = (url: string) =>
  url.replace(/<(\w+)>/g, (_, envVar) => getEnvVar(envVar))
