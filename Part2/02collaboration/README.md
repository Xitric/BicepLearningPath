# Bicep collaboration best practices
## Parameters
- Name parameters to make both the resource they affect and the property they relate to clear.
- Use default values whenever possible. Choose values that work in the majority of cases. If nothing else, the default values provide examples for users.
    - Alternatively consider removing most default values and specify them in parameter files for different environments instead.
- Specify descriptions and constraints on parameters when possible.
    - Only use the `@allowed()` constraint when there are functional reasons why only certain values are permitted for a template. In all other cases, consider using Azure Policies instead.
- Rather than providing long lists of parameters for flexible Bicep templates, consider using configuration sets.
- Configuration sets are particularly useful when we need to enforce complex interdependent rules on the allowed parameter values.

### Configuration sets
A single parameter with a restricted set of allowed values, such as an environment (`test`, `dev`, `staging`, `prod`).
Then, a variable provides a map between allowed environment values and complete configuration objects. Example:

```bicep
@allowed([
    'dev'
    'prod'
])
param env string = 'dev'

var envConfigMap = {
    dev: {
        appServicePlanSkuName: 'cheap'
        enableLogging: false
        ...
    }
    prod: {
        appServicePlanSkuName: 'expensive'
        enableLogging: true
        ...
    }
}
```

As an example, we can then look up configuration values by `envConfigMap[env].appServicePlanSkuName`.

Configuration sets are also useful when specifying guards on deployments, such as by enabling logging only for production environments:

```bicep
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = if (envConfigMap[env].enableLogging) {
  name: 'logAnalyticsWorkspaceName'
  location: resourceGroup().location
}
```

## Resource names
- Expose only naming suffixes as parameters, and hide the complexities of adhering to company and Azure guidelines for resource naming inside the template.
    - Use `uniqueString()` to provide a default value for this naming suffix.
    - Use `@maxLength()` to ensure that the user-provided suffix does not cause the template to exceed Azure resource naming restrictions.
- Dynamically construct resources names in variables using string interpolation. This should include naming suffixes and other relevant properties.
- Follow a [company naming convention](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).
- Incorporate [Azure recommended resource abbreviations](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).
- Adhere to [Azure resource naming restrictions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules).

## Bicep file structure
Bicep files should be structured in the following order:

- targetScope
- param
- var
- resource
- output

Naturally, within large groups of the same element type, related elements should be located together in the template.
The more important resources should be at the top, with supporting resources towards the bottom.

## Resource dependencies
When referring to a property of another resource (could be its name), which also happens to be available as a parameter or variable, _always_ reference this using dot notation on the symbolic name of the other resource, to enable Bicep to schedule the deployment of the two resources sequentially. Otherwise, deployments could fail.

## Documenting
Document only unique logic and complex expressions.
Consider extracting complex properties with function calls and string interpolation to well-named variables, and reference those variables from within resource declarations.
This causes the Bicep template to be mostly self-documenting.

Consider adding a multi-line comment as a manifest at the top of each Bicep template to document its purpose, version, and responsible team members.

Some resource types such as Azure policies and RBAC assignments include a description property for documenting their purpose.
This should always be filled in.

### Resource tagging
Tags are used to track information about deployed resources in Azure beyond what is provided through the resource name itself.
This allows for filtering resources by tags, such as to generate reports or billing.
Use cases include (more [here](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)):

- Recording the name of the responsible team / team member.
- Tracking associated workloads on resources.
- Tracking the name of the environment to which the resource is deployed.
- Tracking ownership of resources.

It is common to use the same set of tags for all resources.
Thus, they should be defined as parameters or variables and reused throughout the template file.
