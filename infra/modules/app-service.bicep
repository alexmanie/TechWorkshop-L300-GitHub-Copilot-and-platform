targetScope = 'resourceGroup'

@description('Base name for app service resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Container registry login server')
param containerRegistryLoginServer string

@description('User assigned managed identity resource ID')
param managedIdentityId string

@description('User assigned managed identity client ID')
param managedIdentityClientId string

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Docker image name and tag')
param dockerImageName string = 'zavastorefront:latest'

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var appServicePlanName = 'asp-${name}-${resourceSuffix}'
var appServiceName = 'app-${name}-${resourceSuffix}'

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2025-03-01' = {
  name: appServiceName
  location: location
  tags: union(tags, {
    'azd-service-name': 'web'
  })
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/${dockerImageName}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
      ]
    }
    httpsOnly: true
  }
}

@description('App Service default hostname')
output uri string = 'https://${appService.properties.defaultHostName}'

@description('App Service name')
output appServiceName string = appService.name
