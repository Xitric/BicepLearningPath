# Bicep first app
## Deploy
To work with the sandboxes in Azure, we must change the subscription used by the Azure CLI. By running `az login` the CLI retrieves a list of all available subscriptions. Then we set the subscription to use with:

```powershell
az account set --subscription "Concierge Subscription"
```

We can also specify the default resource group to use to avoid typing it in to all commands:

```powershell
az configure --defaults group=learn-f6a0524e-00e9-432d-954f-78c355df7090
```

Then we can deploy with:

```powershell
az deployment group create -f .\main.bicep
```
