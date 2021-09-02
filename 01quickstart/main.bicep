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

// We use the storage bicep template as a module to break up the deployment into
// smaller, reusable files. Bicep automatically verifies that all required
// (non-default valued) parameters are passed
module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  // We can even specify the scope that each module is deployed to
  // scope: resourceGroup('somename')
  params: {
    env: env
    location: location
  }
}

// We can forward the outputs from our module, or reference them for other
// purposes such as passing them to other modules
output storageId string = storage.outputs.storageId
