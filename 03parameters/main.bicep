@description('The identifier of the environment in which this template is deployed.')
@allowed([
  'test'
  'dev'
  'staging'
  'prod'
])
param env string = 'dev'

@description('The name of the solution to ensure that resource names are unique.')
@minLength(5)
@maxLength(30)
param solution string = 'toyhr${uniqueString(resourceGroup().id)}'

@description('The number of instances of the app service plan.')
@minValue(1)
@maxValue(10)
param appServicePlanInstanceCount int = 1

@description('The name and tier of the app service plan pricing model.')
param appServicePlanSku object

@description('The Azure regions to deploy the resources into.')
param region string = resourceGroup().location

@secure()
@description('The administrator login username for the sql server.')
param sqlServerAdminLogin string

@secure()
@description('The administrator login password for the sql server.')
param sqlServerAdminPassword string

@description('The name and tier of the database pricing model.')
param sqlDatabaseSku object

var appServicePlanName = '${env}-${solution}-plan'
var appServiceAppName = '${env}-${solution}-app'
var sqlServerName = '${env}-${solution}-sql'
var sqlDatabaseName = 'Employees'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: region
  sku: {
    name: appServicePlanSku.name
    tier: appServicePlanSku.tier
    capacity: appServicePlanInstanceCount
  }
}

resource appServiceApp 'Microsoft.Web/sites@2020-06-01' = {
  name: appServiceAppName
  location: region
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: region
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword:sqlServerAdminPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: region
  sku: {
    name: sqlDatabaseSku.name
    tier: sqlDatabaseSku.tier
  }
}
