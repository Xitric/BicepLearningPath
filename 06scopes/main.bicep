targetScope = 'subscription'

param virtualNetworkName string
param virtualNetworkAddressPrefix string

var policyDefinitionName = 'DenyFandGSeriesVMs'
var policyAssignmentName = 'DenyFandGSeriesVMs'
var resourceGroupName = 'ToyNetworking'

// Define a policy to deny creation of virtual machines with an SKU name for F
// and G series VMs
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2020-03-01' = {
  name: policyDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.Compute/virtualMachines/sku.name'
                like: 'Standard_F*'
              }
              {
                field: 'Microsoft.Compute/virtualMachines/sku.name'
                like: 'Standard_G*'
              }
            ]
          }
        ]
      }
      then: {
        // Alternatively we can use the audit effect which logs the attempt, but
        // does not prevent creation. This can be safer as we avoid causing
        // deployment failures - then we can always clean up afterwards
        effect: 'deny'
      }
    }
  }
}

// Policy definitions have no effect until they are applied
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-03-01' = {
  name: policyAssignmentName
  properties: {
    policyDefinitionId: policyDefinition.id
  }
}

// Since we deploy the subscription-scoped template with an explicit location in
// the deploy command, we can access that location when deploying our resource
// group
resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: deployment().location
}

module virtualNetwork 'modules/virtualNetwork.bicep' = {
  // We can refer to a resource group by its symbolic name, or by using the
  // resourceGroup() function
  scope: rg
  name: 'virtualNetwork'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
  }
}
