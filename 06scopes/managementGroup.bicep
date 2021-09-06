targetScope = 'managementGroup'

// Required only due to a limitation in Bicep for resources deployed at the
// management group scope
param managementGroupName string

var policyDefinitionName = 'DenyFandGSeriesVMs'
var policyAssignmentName = 'DenyFandGSeriesVMs'

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
        effect: 'deny'
      }
    }
  }
}

// As of this writing, Bicep has a limitation where it is not possible to obtain
// full resource IDs for resources deployed at the management group scope. Thus,
// we must construct the ID manually
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-03-01' = {
  name: policyAssignmentName
  properties: {
    // Optimally, we would just write policyDefinition.id, but that does not
    // work for resources in management groups yet

    // Very important that we use policyDefinition.name and NOT
    // policyDefinitionName, to tell Bicep about the dependency between our
    // policy definition and assignment - otherwise they will be created in
    // parallel, and the deployment could fail
    policyDefinitionId: '/providers/Microsoft.Management/managementGroups/${managementGroupName}/providers/Microsoft.Authorization/policyDefinitions/${policyDefinition.name}'
  }
}
