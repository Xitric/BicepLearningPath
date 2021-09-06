# Bicep preview deployment changes
Azure resource manager supports two deployment modes:

- Incremental: The resource manager will not delete any resources. If existing resources are not specified in the deployment template, they will simply be left alone. But the resource manager will add new resources and modify existing ones.
- Complete: Resources not defined in the deployment template will be deleted (some resource types are [exempt from this rule](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-complete-mode-deletion)). Even resources referenced using the `existing` keyword in template files will be removed.

Complete mode can be great to avoid configuration drift, but it requires that all of our infrastructure is defined as code - resources created manually will be removed during a complete deployment.

Complete mode is only available for deployments with a resource group scope.

## What-if
We can use the what-if command to determine what changes a deployment would make to an existing infrastructure:

```powershell
az deployment group what-if -f .\main.bicep --result-format {FullResourcePayloads|ResourceIdOnly}
```

The what-if command supports two levels of detail:

- FullResourcePayloads: A list of resources that will change, as well as details about all properties that will change.
- ResourceIdOnly: Only a list of resources that will change.

We can even get raw JSON output, for instance to analyze in another script, by using the `--no-pretty-print` argument.

We can also run a regular deployment command, but append the `--confirm-with-what-if` argument to preview the changes and accept them before the deployment commences.
