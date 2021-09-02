@description('The identifier of the environment in which this template is deployed.')
@allowed([
  'test'
  'dev'
  'staging'
  'prod'
])
param env string = 'dev'

@description('The Azure region into which the resources should be deployed.')
param region string = resourceGroup().location

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

@description('The name and tier of the SQL database pricing model.')
param sqlDatabaseSku object = {
  name: 'Standard'
  tier: 'Standard'
}

@description('The name of the audit storage account pricing model.')
param auditStorageAccountSkuName string = 'Standard_LRS'

var sqlServerName = 'teddy${region}${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'TeddyBear'
var auditingEnabled = env == 'prod'
// The take function limits the length of the resulting string, trimming off any excess
var auditStorageAccountName = '${take('bearaudit${region}${uniqueString(resourceGroup().id)}', 24)}'

resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: region
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: region
  sku: sqlDatabaseSku
}

resource auditStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = if (auditingEnabled) {
  name: auditStorageAccountName
  location: region
  sku: {
    name: auditStorageAccountSkuName
  }
  kind: 'StorageV2'
}

// It is also sometimes necessary to add deployment guards to property
// expressions inside a resource definition, since they are executed before
// evaluating the deployment guard of the resource itself, and thus may
// reference invalid values
resource sqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2020-11-01-preview' = if (auditingEnabled) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: auditingEnabled ? auditStorageAccount.properties.primaryEndpoints.blob : ''
    storageAccountAccessKey: auditingEnabled ? listKeys(auditStorageAccount.id, auditStorageAccount.apiVersion).keys[0].value : ''
  }
}
