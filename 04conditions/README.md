# Bicep conditions and loops
Property expressions inside a resource definition are evaluated before the deployment condition on the resource itself is evaluated. Thus, we cannot assume that the deployment condition is met when evaluating a property expression, often forcing us to duplicate the deployment guard.

If multiple resources share the same deployment guard, we should consider packing them together as a module, which may also have a deployment guard.

## Deploy
When having multiple sandbox subscriptions, firsts start by listing them using the following command:

```powershell
az account list --refresh --query "[?contains(name, 'Concierge Subscription')].id" --output table
```

Then choose the subsciprion to use by calling:

```powershell
az account set --subscription <id>
```

Lastly, specify the default resource group for dpeloyment, which can be seen on the Azure portal:

```powershell
az configure --defaults group=<id>
```

Then deploy the template with:

```powershell
az deployment group create -f .\main.bicep
```

## Loops
Bicep supports the copy loop syntax on both resource declarations, properties, variables, and output statements - basically anywhere that accepts an array.
Loops can also be nested, for instance if we use a loop on a property inside a resource definition which is itself a loop.

Loops on variables are often used when we want to expose a simple configuration parameter to clients, but need to convert that to a more complex format internally.
For instance, a flat parameter object with many properties can be turned into a complex nested object accepted by an Azure resource property.
