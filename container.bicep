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

@description('VSCode extensions to install (e.g. ms-python.python, leave empty to skip)')
param vscodeExtensions array = []

@description('Number of CPU cores')
param cpuCores int = 1

@description('Memory in GB')
param memoryInGB int = 2

@description('Auto-shutdown after this duration (e.g. 4h, 1d, infinity)')
param autoShutdown string = '1d'

@description('Name of resources shared by container instances (Managed Identity, Log Analytics, network, etc.)')
param sharedName string = resourceGroup().name

// Git Credential Manager version (see https://github.com/git-ecosystem/git-credential-manager/releases/latest)
var gcmVersion = '2.6.1'

// Input validation (ugly hack to avoid using the experimental 'assert' or setting @minLength() which breaks bicepparam)
var assertNameIsNotEmpty = 1 / (length(name) < 3 ? 0 : 1)

var vscodeExtensionArgs = [ for ext in vscodeExtensions: '--install-extension ${ext}' ]

var commandTemplate = '''
  set -euxo pipefail
  exec &> >(tee /root/vscode-aci.log)
  {{gitCommandTemplate}}
  {{vsCodeCommandTemplate}}
  cd /root
  sleep {{autoShutdown}}
  '''

var gitCommandTemplate = replace(replace(replace(replace('''
  (
    curl -sSL https://github.com/git-ecosystem/git-credential-manager/releases/download/v{{gcmVersion}}/gcm-linux_amd64.{{gcmVersion}}.tar.gz --output /tmp/gcm-linux_amd64.tar.gz
    tar -xzf /tmp/gcm-linux_amd64.tar.gz -C /usr/local/bin
    git-credential-manager configure
    git config --global user.name "{{gitUserName}}"
    git config --global user.email "{{gitUserEmail}}"
    git clone --filter=tree:0 --single-branch {{gitRepoUrl}}
  )&
  ''',
  '{{gcmVersion}}', gcmVersion),
  '{{gitRepoUrl}}', gitRepoUrl),
  '{{gitUserEmail}}', gitUserEmail),
  '{{gitUserName}}', gitUserName)

var vsCodeCommandTemplate = replace(replace('''
  (
    curl -sSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" --output /tmp/vscode-cli.tar.gz
    tar -xzf /tmp/vscode-cli.tar.gz -C /usr/local/bin
    code tunnel user login --provider microsoft
    code tunnel --accept-server-license-terms --name {{name}} {{vscodeExtensionArgs}}
  )&
  ''',
  '{{vscodeExtensionArgs}}', join(vscodeExtensionArgs, ' ')),
  '{{name}}', name)

var command = replace(replace(replace(replace(
  commandTemplate,
  '{{gitCommandTemplate}}', gitRepoUrl == '' ? '' : gitCommandTemplate),
  '{{vsCodeCommandTemplate}}', vsCodeCommandTemplate),
  '{{autoShutdown}}', autoShutdown),
  '\r', '')

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  name: sharedName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: sharedName
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: sharedName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2024-11-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    containers: [
      {
        name: 'default'
        properties: {
          image: image
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGB
            }
          }
          environmentVariables: [
            { name: 'GCM_CREDENTIAL_STORE', value: 'cache' }
            { name: 'GCM_AZREPOS_CREDENTIALTYPE', value: 'oauth' }
            { name: 'GCM_AZREPOS_MANAGEDIDENTITY', value: identity.properties.clientId }
          ]
          command: ['/bin/bash', '-c', command]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
    subnetIds: [
      {
        id: '${vnet.id}/subnets/aci'
      }
    ]
    diagnostics: {
      logAnalytics: {
        logType: 'ContainerInstanceLogs'
        workspaceId: logAnalyticsWorkspace.properties.customerId
        #disable-next-line use-secure-value-for-secure-inputs
        workspaceResourceId: logAnalyticsWorkspace.id
        #disable-next-line use-secure-value-for-secure-inputs
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Hack to prevent the compiler from optimizing out the input validation
output inputValidations array = [assertNameIsNotEmpty]
