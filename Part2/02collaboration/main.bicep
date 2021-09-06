@description('The location used for deploying the resources.')
param location string = resourceGroup().location

@allowed([
  'prod'
  'dev'
])
param env string = 'dev'

@description('Suffix to use to ensure that all resource names are unique.')
@maxLength(12)
param uniquenessSuffix string = take(uniqueString(resourceGroup().id), 12)

@description('Username for accessing the SQL database.')
param sqlAdministratorLogin string

@description('Password for accessing the SQL database.')
@secure()
param sqlAdministratorLoginPassword string

var serverFarmName = 'plan-${uniquenessSuffix}-${env}-${location}'
var siteName = 'ase-${uniquenessSuffix}-${env}-${location}'
var siteIdentityName = 'id-${uniquenessSuffix}-${env}-${location}'
var storageAccountName = 'st${uniquenessSuffix}'
var sqlServerName = 'sql-${uniquenessSuffix}-${env}-${location}'
var databaseName = 'sqldb-${uniquenessSuffix}-${env}-${location}'
var blobContainerNames = [
  'productspecs'
  'productmanuals'
]

var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

// Config map with SKU information for different deployment environments
var envConfigMap = {
  prod: {
    serverFarm: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_GRS'
      }
    }
    sqlServerDatabase: {
      sku: {
        name: 'S1'
      }
    }
  }
  dev: {
    serverFarm: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
    sqlServerDatabase: {
      sku: {
        name: 'Basic'
      }
    }
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: serverFarmName
  location: location
  sku: envConfigMap[env].serverFarm.sku
}

resource site 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageAccountConnectionString
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      // This format is required when working with user-assigned managed
      // identities
      '${siteAssignedIdentity.id}': {}
    }
  }
}

resource siteAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: siteIdentityName
  location: location
}

resource databaseConnectionRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  // Role assignments require a GUID for their name
  name: guid(contributorRoleDefinitionId, resourceGroup().id)

  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: siteAssignedIdentity.properties.principalId
    description: 'Assigns the "Contributor" role to the web site managed identity to enable access to the storage account.'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: 'eastus'
  sku: envConfigMap[env].storageAccount.sku
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }

  resource blobServices 'blobServices' existing = {
    name: 'default'
  }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [ for blobContainerName in blobContainerNames: {
  parent: storageAccount::blobServices
  name: blobContainerName
}]

resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: envConfigMap[env].sqlServerDatabase.sku
}

resource sqlServerAllowAllAzureIPs 'Microsoft.Sql/servers/firewallRules@2014-04-01' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: 'AppInsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
