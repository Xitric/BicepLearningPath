# Bicep child and extension resources
Azure resources are specified in Bicep templates using the structure `<provider>/<type>@<version>`.

The `provider` is a logical group of resource types, which are related to a small number of associated Azure services.
These could be network, sql, web, etc.
A resource provider must be registered with the Azure subscription before they can be used in a deployment.

A provider exposes a number of resource `type`s, each of which has its own set of properties and behavior.
For instance, the web provider exposes resource types such as sites and server farms.

Lastly, for each resource type, we must specify the API `version` of the provider we wish to use when provisioning the resource.
The version dictates which properties are available in the template.
Unless we have a good reason, we should lean towards newer versions.

While the above specifies the resource _class_, the instance of such a resource is represented by a unique resource ID.
The format of the ID depends on the target scope to which the template is deployed.
Generally, if a template is deployed at the resource group scope (default), the ID has the format:

```
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}
```

## Child resources
A resource that only makes sense to deploy within the context of its parent.
For instance, it makes no sense to depoy a subnet without a virtual network.
It also makes no sense to deploy an SQL database without an SQL server to contain it.

As a result, child resource types have longer names.
While a virtual network has the type name `virtualNetworks`, subnets are named `virtualNetworks/subnets`. Thus, to provision a subnet, we would have to write:

```
Microsoft.Network/virtualNetworks/subnets@<version>
```

To construct the ID of a child resource, we take the ID of the parent resource and append the resource type of the child along with the name of the child resource instance.

Child resources can be specified in a number of ways.

### Nested
To provision the child resource `Microsoft.Compute/virtualMachines/extensions`, we can use the format:

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    ...

    resource vmExtension 'extensions' = {
        ...
    }
}
```

Notice how the parent resource is implicit from the nesting, and the provider API version is automatically inherited.
However, we can override the API version on the child resource, should we wish to do so.

When using this technique, the child resource symbolic name is tied to the namespace of the parent resource, so we refer to it with `vm::vmExtension`.

### Parent property
Alternatively, we can specify the child resource separately and just reference the parent:

```bicep
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
    parent: vm
    ...
}
```

Then we can refer to the symbolic name of the child resource directly.

### Resource name
If the two other options are not possible, we can make the parent-child relationship clear by carefully constructing the name of the child resource:

```bicep
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
    name: '${vm.name}/InstallCustomScript'
    ...
}
```

It is _vital_ to reference the name property on the parent resource when constructing the child resource name - otherwise Bicep will not know to deploy the parent resource first.
Alternatively, we have to specify the dependency between the two resources by adding a `dependsOn` property to the child resource.

## Extension resources
Resources that are always attached to other resources, and which extend their behavior or add something extra to them.
For instance, a `Microsoft.Authorization/locks`, which can be attached to another resource to prevent it from being deleted.
Or `Microsoft.Authorization/roleAssignments` which can be used to grant permissions to a resource.

They are declared just the same as ordinary resources, except they contain a `scope` parameter specifying the symbolic name of the resource they are extending.

The resource ID of an extension is similar to that of an ordinary resource, except it appears under a second level of providers on the resource that it extends (notice `providers` appears twice):

```
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}/providers/{extensionProviderNamespace}/{extensionType}/{extensionName}
```

## External/existing resources
Used when we need to reference resources that already exist in Azure, either because they originate from a different Bicep file, or because they were manually created in the portal.
This is for instance useful when accessing secrets in an existing key vault:

```bicep
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
    name: 'kvName'
    scope: resourceGroup('subscriptionId', 'kvResourceGroup')
}
// kv.getSecret('secretName')
```

As shown, we can also refer to existing resources that belong to a different resource group, or even to an entirely different subscription using the `scope` property.

If we need to access secure data from another resource (such as a secret key), we should not use outputs, but rather access that data as a property on an existing resource declaration to avoid exposure.
