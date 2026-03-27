targetScope = 'resourceGroup'

@description('Base name for AI Foundry resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Resource ID of the AI Services account to connect (provides Phi-4 model access)')
param aiServicesId string

@description('Endpoint of the AI Services account')
param aiServicesEndpoint string

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var storageAccountName = toLower('st${take(replace(name, '-', ''), 10)}${resourceSuffix}')
var hubName = 'aif-${name}-${resourceSuffix}'
var projectName = 'aifp-${name}-${resourceSuffix}'

// Storage account required by AI Foundry Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// AI Foundry Hub workspace
resource aiFoundryHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: hubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageAccount: storageAccount.id
    publicNetworkAccess: 'Enabled'
  }
}

// Connect AI Services (with Phi-4 deployment) to the Hub
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = {
  parent: aiFoundryHub
  name: 'ai-services'
  properties: {
    category: 'AIServices'
    target: aiServicesEndpoint
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: listKeys(aiServicesId, '2025-09-01').key1
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServicesId
    }
  }
}

// AI Foundry Project (child workspace under the Hub)
resource aiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: projectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hubResourceId: aiFoundryHub.id
    publicNetworkAccess: 'Enabled'
  }
}

@description('AI Foundry Hub resource ID')
output hubId string = aiFoundryHub.id

@description('AI Foundry Hub name')
output hubName string = aiFoundryHub.name

@description('AI Foundry Project resource ID')
output projectId string = aiFoundryProject.id

@description('AI Foundry Project name')
output projectName string = aiFoundryProject.name
