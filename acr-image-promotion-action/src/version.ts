import * as fs from 'fs'
import * as path from 'path'

interface VersionInfo {
  version: string
  buildDate: string
  gitHash: string
  formattedVersion: string
}

export function getVersionInfo(): VersionInfo {
  const version = getVersion()
  const buildDate = getBuildDate()
  const gitHash = getGitHash()
  
  return {
    version,
    buildDate,
    gitHash,
    formattedVersion: `${version}+${buildDate}+${gitHash}`
  }
}

function getVersion(): string {
  try {
    const packagePath = path.join(__dirname, '..', 'package.json')
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'))
    return packageJson.version || '1.0.0'
  } catch {
    return '1.0.0'
  }
}

function getBuildDate(): string {
  return Math.floor(Date.now() / 1000).toString()
}

function getGitHash(): string {
  try {
    return process.env.GITHUB_SHA?.substring(0, 7) || 'unknown'
  } catch {
    return 'unknown'
  }
}

export function logVersionInfo(): void {
  const versionInfo = getVersionInfo()
  console.log(`Version: ${versionInfo.formattedVersion}`)
  console.log(`  - Version: ${versionInfo.version}`)
  console.log(`  - Build Date: ${versionInfo.buildDate}`)
  console.log(`  - Git Hash: ${versionInfo.gitHash}`)
}