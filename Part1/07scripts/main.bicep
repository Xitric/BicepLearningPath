@description('List of files to copy to application storage account.')
param filesToCopy array = [
  'appsettings.json'
]

var storageAccountName = 'storage${uniqueString(resourceGroup().id)}'
var storageBlobContainerName = 'config'
var deploymentScriptName = 'CopyConfigScript'

var userAssignedIdentityName = 'configDeployer'
// We must generate a unique GUID for a role assignment, similar to how roles
// have a GUID
var roleAssignmentName = guid(resourceGroup().id, 'contributor')
// We can also obtain the resource ID of the role from its GUID (Contributor
// role)
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  tags: {
    displayName: storageAccountName
  }
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }

  // Reference implicitly created child resource (default blob service)
  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-04-01' = {
  parent: storageAccount::blobService
  name: storageBlobContainerName
  properties: {
    publicAccess: 'Blob'
  }
}

// To run the script, we must use managed identities and RBAC to give it some
// permissions. First, we create a new blank identity
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location
}

// Then we assign some roles to it (Contributor role)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  dependsOn: [
    roleAssignment
    blobContainer
  ]
  properties: {
    azPowerShellVersion: '5.0'
    scriptContent: loadTextContent('downloadAssets.ps1')
    retentionInterval: 'P1D'
    arguments: '-File \'${string(filesToCopy)}\''
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'StorageContainerName'
        value: storageBlobContainerName
      }
    ]
  }
}

output fileUri object = deploymentScript.properties.outputs
output storageAccountName string = storageAccountName
