targetScope = 'resourceGroup'

@description('Base name for AI services resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('GPT-4 model deployment capacity (in thousands of tokens per minute)')
param gpt4Capacity int = 1

@description('Phi model deployment capacity (in thousands of tokens per minute)')
param phiCapacity int = 1

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var aiServicesName = 'ai-${name}-${resourceSuffix}'

resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = {
  parent: aiServicesAccount
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: 'turbo-2024-04-09'
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = {
  parent: aiServicesAccount
  name: 'Phi-4'
  dependsOn: [gpt4Deployment]
  sku: {
    name: 'GlobalStandard'
    capacity: phiCapacity
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
    }
  }
}

@description('AI Services account endpoint')
output endpoint string = aiServicesAccount.properties.endpoint

@description('AI Services account name')
output accountName string = aiServicesAccount.name

@description('AI Services account resource ID')
output id string = aiServicesAccount.id
