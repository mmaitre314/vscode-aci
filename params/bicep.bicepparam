using './main.bicep'

param name = '' // Specify on the command line
param image = 'mcr.microsoft.com/azure-cli'
param vscodeExtensions = [ 'ms-azuretools.vscode-bicep' ]
