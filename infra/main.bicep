targetScope = 'subscription'

@description('Name of the environment (used for resource naming)')
param environmentName string

@description('Location for all resources')
param location string

@description('Principal ID of the deploying user (required by AZD)')
#disable-next-line no-unused-params
param principalId string

var tags = {
  'azd-env-name': environmentName
}

var resourceGroupName = 'rg-${environmentName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Monitoring: Log Analytics + Application Insights
module monitoring 'modules/monitoring.bicep' = {
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    tags: tags
  }
}

// Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    tags: tags
  }
}

// Managed Identity with AcrPull role
module managedIdentity 'modules/managed-identity.bicep' = {
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    tags: tags
    containerRegistryId: containerRegistry.outputs.id
    aiServicesId: aiServices.outputs.id
  }
}

// App Service (Linux with Docker from ACR)
module appService 'modules/app-service.bicep' = {
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    tags: tags
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    managedIdentityId: managedIdentity.outputs.id
    managedIdentityClientId: managedIdentity.outputs.clientId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    aiServicesEndpoint: aiServices.outputs.endpoint
  }
}

// Azure AI Services (GPT-4 and Phi deployments)
module aiServices 'modules/ai-services.bicep' = {
  scope: resourceGroup
  params: {
    name: environmentName
    location: location
    tags: tags
  }
}

// Outputs for AZD
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.registryName
output WEB_URI string = appService.outputs.uri
output AZURE_AI_SERVICES_ENDPOINT string = aiServices.outputs.endpoint
