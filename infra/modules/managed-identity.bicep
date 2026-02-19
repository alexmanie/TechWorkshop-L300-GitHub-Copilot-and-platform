targetScope = 'resourceGroup'

@description('Base name for the managed identity')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Container registry resource ID for AcrPull role assignment')
param containerRegistryId string

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var identityName = 'id-${name}-${resourceSuffix}'

// AcrPull built-in role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: identityName
  location: location
  tags: tags
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: last(split(containerRegistryId, '/'))
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

@description('Managed identity resource ID')
output id string = managedIdentity.id

@description('Managed identity principal ID')
output principalId string = managedIdentity.properties.principalId

@description('Managed identity client ID')
output clientId string = managedIdentity.properties.clientId
