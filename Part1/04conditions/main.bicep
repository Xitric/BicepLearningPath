@description('The Azure regions into which the resources should be deployed.')
param locations array = [
  'westeurope'
  'eastus2'
  'eastasia'
]

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

@description('The IP address range for all virtual networks to use.')
param virtualNetworkAddressPrefix string = '10.10.0.0/16'

// First, we expose a simple, flat parameter for clients to configure subnets
@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array = [
  {
    name: 'frontend'
    ipAddressRange: '10.10.5.0/24'
  }
  {
    name: 'backend'
    ipAddressRange: '10.10.10.0/24'
  }
]

// Using variable loops, we convert the flat parameter into a nested object
// understood by Azure. Alternatively, we could handle this as a nested loop
// directly in the resource definition further below
var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
}]

// By default, Bicep will deploy all resources in a loop in parallel and in a
// non-deterministic order to speed up deployment times. We can control this by
// forcing Bicep to deploy our resources in batches of a fixed size. A size of 1
// results in a sequential loop
@batchSize(1)
module databases 'modules/database.bicep' = [for location in locations: {
  name: 'database-${location}'
  params: {
    region: location
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}]

// We use a copy loop to create multiple resources at once
resource virtualNetworks 'Microsoft.Network/virtualNetworks@2020-11-01' = [for location in locations: {
  name: 'teddybear-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: subnetProperties
  }
}]

// We cannot access the resource definition array 'databases' in an output loop
// yet, so we iterate with a range based on the locations array
output serverInfo array = [for i in range(0, length(locations)): {
  name: databases[i].outputs.serverName
  location: databases[i].outputs.location
  fullyQualifiedDomainName: databases[i].outputs.serverFullyQualifiedDomainName
}]
