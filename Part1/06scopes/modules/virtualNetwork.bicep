// targetScope of resource group if inferred by default

param virtualNetworkName string
param virtualNetworkAddressPrefix string

// This module is deployed with a resource group scope, which means we can
// access the location of the resource group
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
  }
}
