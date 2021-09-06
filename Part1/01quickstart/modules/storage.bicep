// Parameters for this template with default values and decorators
// Here the default value is obtained through a Bicep function that returns the
// current resource group scope
@description('The region in which to deploy all resources')
@metadata({
  test: 'Hello, world!'
})
param location string = resourceGroup().location

@description('The environment to run the resources')
@allowed([
  'test'
  'dev'
  'staging'
  'prod'
])
param env string

// Variable for storing shared values
var resourceSku = 'Standard_LRS'

var archivenames = [
  'archived1'
  'archived2'
]

// A declaration of a resource to be provisioned in Azure
// Its name is created from string interpolation with Bicep functions
resource stmystorage001 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stmystorage${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'Storage'
  // Pricing tier
  sku: {
    name: resourceSku
  }
  tags: {
    Environment: env
  }
}

// In Bicep, dependencies between resources is automatically inferred from
// property references, so this cannot be created before the storage account
// exists
// Furthermore, we only provision this resource if the environment is test
resource blob 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = if(env == 'test') {
  name: '${stmystorage001.name}/default/logs'
}

// We can use loops to provision similar resources based on entries in an array.
// There is also a variant that exposes both the element and its index
resource blobs 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = [for blobname in archivenames: {
 name: '${stmystorage001.name}/default/${blobname}'
}]

// If we wish to reference an existing resource (to bind it to a symbolic name
// in the template), we can use this syntax. If the resource exists in a
// different scope than that targeted by the Bicep file, we can specify that
// scope explicitly:
// resource stexistingstorage001 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
//   name: 'thename'
//   scope: resource_group_scope
// }

// Outputs that become available for scripts and other bicep files, like outputs
// in an AWS stack. Useful if we need to reference something across templates
output storageId string = stmystorage001.id

// For properties that only exist after the resource has been created (as
// opposed to existing at compile time) we access them like so
output blobEndpoint string = stmystorage001.properties.primaryEndpoints.blob

// We can also create loops based on ranges. The first parameter specifies the
// start value, and the second specified the NUMBER OF items to generate (not
// the upper limit)
output archivedLogIds array = [for i in range(0, length(archivenames)): blobs[i].id]
