using './main.bicep'

param name = '' // Specify on the command line
param image = 'mcr.microsoft.com/devcontainers/python:dev-3.13'
param vsCodeExtensions = [ 'ms-python.python', 'ms-toolsai.jupyter', 'github.copilot-chat' ]
