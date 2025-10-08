<p align="center">
  <picture>
    <img alt="VSCode ACI" src="https://raw.githubusercontent.com/mmaitre314/vscode-aci/main/docs/logo.jpg" style="width: 30%;">
  </picture>
  <br/>
  <br/>
</p>

# VSCode Dev Containers on Azure Container Instances

Code with multiple GitHub Copilot agents in parallel using VSCode and Dev Containers on Azure Container Instances.

## Quickstart

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmmaitre314%2Fvscode-aci%2Frefs%2Fheads%2Fmain%2Fdeploy%2Fmain.azuredeploy.json)

Click on [Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmmaitre314%2Fvscode-aci%2Frefs%2Fheads%2Fmain%2Fdeploy%2Fmain.azuredeploy.json), select a resource group and a resource name, click 'Review + Create', and finally click 'Create'.

Once the deployment completes, open the Azure Container Instance, go to 'Settings > Containers > Logs', and find the device code to enter at https://microsoft.com/devicelogin . After logging in, refresh the logs to find the VS Code URL to open and connect to the container. It will begin with https://vscode.dev/ .

## Deployment Configuration

### Git

To setup Git, fill in the 'Git Repo URL' field of the deployment. The repo will be cloned to `/root/<repo-name>` in the container

To clone a private Git repo from Azure DevOps (ADO), grant the Managed Identity in the Resource Group access to the ADO repo (for instance by adding it to an ADO Team).

### VSCode Extension

To have VSCode Extensions auto-installed during deployment, fill-in the 'Vscode Extensions' field of the deployment with a JSON array of extension IDs. For instance:
- For Python: `[ "ms-python.python", "ms-toolsai.jupyter", "github.copilot-chat" ]`
- For Bicep: `[ "ms-azuretools.vscode-bicep", "github.copilot-chat" ]`

### Container Initialization Command

To run some extra shell commands during container initialization (e.g. `apt install git-all` to install Git if missing from the image), fill-in the 'Init Command' field.

### Container Size

The size of the container is controlled by the fields 'Cpu Cores' and 'Memory In GB'. The default is 1 core with 2GB, costing around $1.20/day (as of 10/2025).

### Auto Shutdown

The container automatically shuts down after some time to avoid runaway costs. The default is 1 day, which can be changed via the 'Auto Shutdown' field, using the format of the [`sleep`](https://www.man7.org/linux/man-pages/man1/sleep.1.html) command (i.e. `infinity` to never shut down, `7d` to shut down after 7 days, `3h` to shut down after 3 hours, etc.). Container activity is not taken into account.

## Alternative Deployments

Using [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) (in the browser via [Cloud Shell](https://portal.azure.com/#cloudshell/)):
```bash
az deployment group create --subscription <subscription-id> --resource-group <resource-group-name> --template-file main.bicep --parameters params/python.bicepparam name=<container-name> --output tsv --query properties.outputs.instructions.value
```

## Dev Container Images

A few images:

Language | Image
--|--
.NET | `mcr.microsoft.com/devcontainers/dotnet:dev-9.0`
C++ | `mcr.microsoft.com/devcontainers/cpp`
Go | `mcr.microsoft.com/devcontainers/go:dev-1.25`
Java | `mcr.microsoft.com/devcontainers/java:dev-21`
NodeJS | `mcr.microsoft.com/devcontainers/javascript-node:dev-24`
Python | `mcr.microsoft.com/devcontainers/python:dev-3.13`
Rust | `mcr.microsoft.com/devcontainers/rust:dev-1`

For more images, see https://mcr.microsoft.com?search=devcontainers .

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

The ARM templates `params/*.azuredeploy.json` are generated from Bicep files using [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest):
```bash
az bicep build --file src/main.bicep --outfile deploy/main.azuredeploy.json
az bicep build --file src/container.bicep --outfile deploy/container.azuredeploy.json
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

- Bicep: improve param descriptions -> test in Deploy to Azure
    `image` param: add MCR deep link to description
- README:
    - quickstart + other install methods
    - mention bicepparam akin to devcontainer.json settings (link: https://mcr.microsoft.com?search=devcontainers)
    - VSCode online: https://vscode.dev/
- Add User settings to container
    "chat.tools.terminal.autoApprove": { updates? }, "chat.agent.maxRequests": 100,
