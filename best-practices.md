# Bicep best practices
Recommended file structure for Bicep templates:

![Bicep file structure](https://docs.microsoft.com/en-us/learn/modules/structure-bicep-code-collaboration/media/4-group-element-type.png)

The more important resources should be at the top, with supporting resources towards the bottom.

Related resources should also be placed close to one another within the Bicep template.

## Parameters

- Place all parameter declarations at the top of the file.

- Use parameters purely for settings that change between deployments, and rely on variables and hard-coded values for all other cases.

- Provide desciptions for all parameters, including any restrictions that may apply to values.

    - To the extent possible, use constraints to enforce such restrictions.

- Default values should be used whenever possible, if for nothing else to provide examples. These values should be chosen to be widely applicable, as well as safe and cheap for anyone to deploy.

- Limit the use of the `@allowed` decorator to settings whose values are limited for functional reasons. For enforcing company policies, such as SKUs or deployment locations, use policies instead.

- For parameters that control naming of resources, limit the minimum and maximum character length to comply with the [Azure resource naming restrictions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules).

- If a property is only expected to take on a limited set of well-defined values across specific types of deployments (such as deployment environments), consider using a config map instead of a parameter.

    - Config maps can also be used to enforce complex interdependent rules on allowed settings.

## Variables

- Place all variables just below the parameters section of the Bicep template.

- Use camel case for variable names.

## Naming

- Resource names must follow the official Bizzkit resource naming guidelines. (TODO: Link)

- Resource names must comply with the [Azure resource naming restrictions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules).

- Encapsulate the complexity of generating resource names inside variables using string interpolation. If necessary, a naming suffix can be exposed as a parameter, to ensure that dynamically generated resource names are unique.

- Use the `uniqueString()` function as part of creating globally unique resource names. Ensure that the parameter passed to this function is the same for all instances of the same deployment, as otherwise the Azure Resource Manager constructs a new resource each time.

- Do not use the output of `uniqueString()` at the beginning of a resource name, since it may begin with a number which is not always allowed according to the [Azure resource naming restrictions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules).

## Tagging

- Use the standard set of tags for all resources throughout a Bicep template. These tags can be constructed in a variable for easy assignment across all resources.

TODO: Decide on a tagging strategy, inspiration [here](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging).

## Resource definitions

- Extract complex expressions from resource properties into well-named variables to make the template self-documenting.

- When referring to the value of a property on an existing resource, always prefer to access this value via a symbolic reference, even if a parameter or independent variable is assumed to store the same value.

    - Not only is this guaranteed to return the most up-to-date value, but it also helps Bicep to infer resource dependencies and plan deployments.

- It's a good idea to use a recent API version for each resource. New features in Azure services are sometimes available only in newer API versions.

- When possible, avoid using the `reference()` and `resourceId()` functions in your Bicep file. You can access any resource in Bicep by using the symbolic name.

- Instead of passing property values around through outputs, use the `existing` keyword to look up properties of resources that already exist via symbolic names. This provides the most up-to-date data.

## Child resources

- Limit nesting of child resources to two layers deep. Beyond this depth, use the `parent` keyword instead.

- If possible, never create child resources by constructing resource names. Always use nesting or the parent keyword.

- If a resource supports implicit child resources such as the `subnets` property on a virtual network, prefer using this over the `parent` keyword.

## Outputs

- Use resource properties whenever possible when creating outputs rather than constructing outputs manually via string interpolation. Sometimes our assumptions aren't correct in different environments, or the resources change the way they work.

- Never create outputs for sensitive or otherwise secret data. Prefer accessing such values as properties on existing resources, or move the responsibility to the Azure Key Vault.

## Documenting

- Add a multi-line comment as a manifest at the top of each Bicep template to document its purpose, version, and responsible team members.

- Document only unique logic, complex expressions, or workarounds for odd behavior in the Azure Resource Manager.

- Some resource types such as Azure policies and RBAC assignments include a description property for documenting their purpose. This must always be filled in for future reference.
