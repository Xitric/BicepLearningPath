# Deploy to other scopes
## Deployment
Due to this template having to be deployed to a subscription scope, we need to provide more information in the dpeloyment command:

```powershell
templateFile="main.bicep"
today=$(date +"%d-%b-%Y")
deploymentName="sub-scope-"$today
virtualNetworkName="rnd-vnet-001"
virtualNetworkAddressPrefix="10.0.0.0/24"

az deployment sub create \
    --name $deploymentName \
    --location westus \
    --template-file $templateFile \
    --parameters virtualNetworkName=$virtualNetworkName \
                 virtualNetworkAddressPrefix=$virtualNetworkAddressPrefix
```

## Resource scopes
In general, an Azure environment for a company may be organized as follows:

![Azure environment hierarchy](https://docs.microsoft.com/en-us/learn/modules/deploy-resources-scopes-bicep/media/2-hierarchy.png)

The hierarchy contains these elements:

- Tenant: The central Azure AD for the company.
- Management group: A hierarchy of groups that specify policies and access-control restrictions. They are inherited by all subscriptions below.
- Subscription: Separate billing accounts.
- Resource group: Logical containers for resources.

Some resources do not naturally belong to resource groups (the default target scope). Some resources instead belong at the subscription level, and extension resources are deployed at the scope of the resource they extend.
Bicep supports targeting different scopes when deploying resources, as illustrated below:

![Azure resources in different scopes](https://docs.microsoft.com/en-us/learn/modules/deploy-resources-scopes-bicep/media/1-architecture-diagram.png)

To specify the scope of an entire Bicep template file, we must specify the `targetScope` property in the top of the file. We must also specify the scope in the deployment command.

> Azure stores metadata about all deployments in a specific location. For resource group deployments, the location is inherited from the resource group. For dpeloyments to subscriptions, management groups, and tenants, we need to explicitly specify the location to store the metadata.

If we need to target multiple scopes in a single deployment, we can also specify the target scope of individual modules by using the `scope` property on a module declaration:

```bicep
module networkModule 'modules/network.bicep' = {
  scope: resourceGroup('subscriptionId', 'resourceGroup')
  name: 'networkModule'
}
```

### Subscription-scope

- Creating new resource groups
- Defining access control
- Specifying subscription-wide policies (for instance about allowed SKUs)

### Management group-scope

- Defining access control for multiple subscriptions
- Company-wide policies (for instance blocking deployments in certain regions)

### Tenant-scope

- Creating new subscriptions
- Creating or configuring management groups
