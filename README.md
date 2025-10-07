# VSCode Dev Containers on Azure Container Instances

Code with multiple GitHub Copilot agents in parallel using VSCode and Dev Containers on Azure Container Instances.

## Quickstart

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmmaitre314%2Fvscode-aci%2Frefs%2Fheads%2Fmain%2Fazuredeploy.json)

Sign in at https://microsoft.com/devicelogin with the device code provided.

If cloning a Git repo from Azure DevOps (ADO), grant the Managed Identity access to the ADO repo (for instance by adding it to an ADO Team).

## Alternative Deployments

Using [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) (in the browser via [Cloud Shell](https://portal.azure.com/#cloudshell/)):
```bash
az deployment group create --subscription <subscription-id> --resource-group <resource-group-name> --template-file main.bicep --parameters python.bicepparam name=<container-name> --output tsv --query properties.outputs.instructions.value
```

## Troubleshooting

### Container fails to start

Get live logs:
```bash
az container attach --subscription <subscription-id> --resource-group <resource-group-name> --name <aci-name>
```
Get recent logs:
```bash
az container attach --subscription <subscription-id> --resource-group <resource-group-name> --name <aci-name>
```
Get a shell to check the container:
```bash
az container exec --subscription <subscription-id> --resource-group <resource-group-name> --name <aci-name> --exec-command /bin/bash
```
Start the container:
```bash
az container start --subscription <subscription-id> --resource-group <resource-group-name> --name <aci-name>
```

### Git fails to authenticate with Azure DevOps (ADO)

Ensure the managed identity has sufficient permissions on the Git repo.

Check Git and Git Credential Manager (GCM) logs:
```bash
export GIT_TRACE=1
export GIT_TRACE_CURL=1
export GCM_TRACE=1
git clone https://xxx
```

### VSCode connects but the container is not fully set up

For instance, the Git repo was not cloned, etc. See setup logs in `/root/vscode-aci.log`.

## Development

The ARM template `azuredeploy.json` is generated from the Bicep file `main.bicep`:
```bash
az bicep build --file main.bicep --outfile azuredeploy.json
```

## References

VSCode:
- [VSCode Online](https://vscode.dev/)
- [VSCode Server](https://code.visualstudio.com/docs/remote/vscode-server)
- [VSCode Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Images](https://github.com/devcontainers/images/)
- [ilteoood/vscode-remote-tunnels](https://github.com/ilteoood/vscode-remote-tunnels)

Azure:
- [Azure Container Instance - Quickstart Bicep](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-quickstart-bicep?tabs=CLI)
- [Deploy-to-Azure button](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button)

Git Credential Manager:
- [Install](https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md)
- [Environment Variables](https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/environment.md)

## Backlog

- Fix Deploy to Azure button
- Bicep: improve param descriptions -> test in Deploy to Azure
    `image` param: add MCR deep link to description
- README:
    - quickstart + other install methods
    - mention bicepparam akin to devcontainer.json settings (link: https://mcr.microsoft.com?search=devcontainers)
    - VSCode online: https://vscode.dev/
- Add User settings to container
    "chat.tools.terminal.autoApprove": { updates? }, "chat.agent.maxRequests": 100,
- Add README logo
