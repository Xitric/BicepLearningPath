# Bicep deployment scripts
When a deployment entail more than just provisioning Azure resources, we can execute custom deployment scripts during a deployment.
This could for instance include adding some assets to a storage account.

Deployment scripts are PowerShell or Bash scripts that are executed in a Docker container during a deployment.
By using the `dependsOn` property, we can control when a script is allowed to run.
These scripts have access to the Azure CLI.
A deployment script produces some outputs that other resources in a deployment can make use of.

## Passing parameters
We can pass parameters to a script either through the `arguments` property (similar to providing arguments in the command line), or through `environmentVariables`. In both cases, we can refer to template parameters, variables, as well as outputs and properties from other resources:

```bicep
properties: {
  arguments: '-Name Learner'
  environmentVariables: [
    {
      name: 'Subject'
      value: 'Deployment Scripts'
    }
    // This environment variable is secured from being exposed during deployment
    {
      name: 'MySecretValue'
      secureValue: 'PleaseDoNotPrintMeToTheConsole!'
    }
  ]
  ...
}
```
