@description('Container instance name')
param name string

@description('Resource location')
param location string = resourceGroup().location

@description('Dev Container image name')
param image string = 'mcr.microsoft.com/devcontainers/python:dev-3'

@description('URL of Git repository to clone')
param gitRepoUrl string = ''

param gitUserEmail string = deployer().userPrincipalName

param gitUserName string = split(deployer().userPrincipalName, '@')[0]

@description('VSCode extensions to install (e.g. ["ms-python.python"], leave empty to skip)')
param vscodeExtensions array = []

@description('Command to run during container initialization (e.g. "apt install git-all", leave empty to skip)')
param initCommand string = ''

@description('Number of CPU cores')
param cpuCores int = 1

@description('Memory in GB')
param memoryInGB int = 2

@description('Auto-shutdown after this duration (e.g. 4h, 1d, infinity)')
param autoShutdown string = '1d'

@description('Name of resources shared by container instances (Managed Identity, Log Analytics, network, etc.)')
param sharedName string = resourceGroup().name

@description('Service tag for outbound network traffic (leave empty in most cases)')
param serviceTag string = ''

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: sharedName
  location: location
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: sharedName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

module network 'network.bicep' = {
  name: '${name}-network'
  params: {
    name: sharedName
    location: location
    serviceTag: serviceTag
  }
}

module container 'container.bicep' = {
  name: '${name}-container'
  params: {
    name: name
    location: location
    image: image
    gitRepoUrl: gitRepoUrl
    gitUserEmail: gitUserEmail
    gitUserName: gitUserName
    vscodeExtensions: vscodeExtensions
    initCommand: initCommand
    cpuCores: cpuCores
    memoryInGB: memoryInGB
    autoShutdown: autoShutdown
  }
  dependsOn: [
    identity
    logAnalyticsWorkspace
    network
  ]
}

@description('VSCode tunnel instructions')
output instructions string = 'Check container logs to get the device-code login:\n    az container logs --subscription ${subscription().subscriptionId} --resource-group ${resourceGroup().name} --name ${name}\nOpen VSCode: https://vscode.dev/tunnel/${name}'
