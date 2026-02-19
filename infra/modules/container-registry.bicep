targetScope = 'resourceGroup'

@description('Base name for the container registry')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

// Generate unique suffix (ACR names must be alphanumeric)
var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var registryName = replace('acr${name}${resourceSuffix}', '-', '')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

@description('Container registry login server')
output loginServer string = containerRegistry.properties.loginServer

@description('Container registry resource ID')
output id string = containerRegistry.id

@description('Container registry name')
output registryName string = containerRegistry.name
