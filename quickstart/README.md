# Bicep quickstart
This repository uses bicep modules to break a deployment into smaller, more manageable template files.

## Deploy
The [parameters for the template](https://docs.microsoft.com/en-gb/azure/azure-resource-manager/templates/template-tutorial-use-parameter-file?tabs=azure-powershell) are specified in `az.parameters.$ENV.json`, and the template can be deployed with:

```powershell
az deployment group create -f .\main.bicep -g <resource_group_name> --parameters .\az.parameters.test.json --mode Complete
```

Template deployments by default target a resource group for deployment. To [target a different scope](https://github.com/Azure/bicep/blob/main/docs/spec/resource-scopes.md), we must both fill in the `targetScope` property of the template and adapt the deployment command:

```powershell
az deployment <scope_identifier> create ...
```
