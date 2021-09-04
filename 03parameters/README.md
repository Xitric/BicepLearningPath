# Bicep parameters and key vault
## Parameters
Parameters can be declared either as default values, from a parameter file, or from the command line arguments. This is also the order of precedence.

![Order of precedence of specifying parameters to Bicep templates](https://docs.microsoft.com/en-gb/learn/modules/build-reusable-bicep-templates-parameters/media/4-precedence.png)

To specify parameters directly on the command line, we can simply use this format:

```powershell
az deployment group create -f .\main.bicep --parameters main.parameters.dev.json <param_name>=<value>
```

## Secrets
When deploying a template with secrets, the parameter file can reference identifiers of secrets in Azure key vault rather than listing raw values. During the dpeloyment, this will trigger the Azure Resource Manager to contact the key vault on our behalf an pull out the secrets to populate template parameters. We can even refer to key vaults from different resource groups and subscriptions.

![Azure Resource Manager looking up secrets during template deployment](https://docs.microsoft.com/en-gb/learn/modules/build-reusable-bicep-templates-parameters/media/5-parameter-file-key-vault.png)

Both the user deploying the template as well as Azure Resource Manager itself must be given access to 

Alternatively, we can access the key vault directly in the Bicep template as such:

```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

module applicationModule 'application.bicep' = {
  name: 'application-module'
  params: {
    apiKey: keyVault.getSecret('ApiKey')
  }
}
```

## Key vault
To create a key vault, we can execute the following:

```bash
keyVaultName='dev-toyhr-kv'
login='toyfacadm'
password='ifh5n$DF4H&fg'

az keyvault create --name $keyVaultName --location westus --enabled-for-template-deployment true
az keyvault secret set --vault-name $keyVaultName --name "sqlServerAdministratorLogin" --value $login
az keyvault secret set --vault-name $keyVaultName --name "sqlServerAdministratorPassword" --value $password
```

Then using this command to get its resource ID:

```powershell
az keyvault show --name $keyVaultName --query id --output tsv
```
