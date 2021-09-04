# Deploy and manage resources in Azure by using Bicep
My implementations while taking the [Azure Bicep course](https://docs.microsoft.com/en-us/learn/paths/bicep-deploy/) on  Microsoft Learn.

## Deploy
When having multiple sandbox subscriptions, first start by listing them using the following command:

```powershell
az account list --refresh --query "[?contains(name, 'Concierge Subscription')].id" --output table
```

Then choose the subsciprion to use by calling:

```powershell
az account set --subscription <id>
```

Lastly, specify the default resource group for deployment, which can be seen on the Azure portal:

```powershell
az configure --defaults group=<id>
```

Then deploy a template by navigating into its directory and running:

```powershell
az deployment group create -f .\main.bicep
```

If the template requires a parameter file, use this command:

```powershell
az deployment group create -f .\main.bicep --parameters main.parameters.dev.json
```
