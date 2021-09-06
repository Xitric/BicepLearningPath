param region string = resourceGroup().location
param env string = 'test'

// The storage account and site must use globally unique names, so it is
// important that they can be overridden by parameter values
param storageAccountName string = 'sttoyshop${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'ase-toyshop-${env}-${region}-${uniqueString(resourceGroup().id)}'

// The service plan needs only be unique in its resource group, so we can be
// more lenient with its name
var appServicePlanName = 'plan-toyshop-${env}-${region}-${uniqueString(resourceGroup().id)}'

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: region
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: region
  sku: {
    name: 'F1'
    tier: 'Free'
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
