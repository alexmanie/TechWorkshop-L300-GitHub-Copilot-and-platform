# Deployment Guide

This workflow builds the .NET app as a Docker image, pushes it to Azure Container Registry, and deploys it to Azure Container Apps. It triggers on:

- **Push** to `main` when files under `src/` change
- **Pull requests** to any branch when files under `src/` change
- **Manual dispatch** via the Actions UI

## Prerequisites

- Infrastructure deployed via the `infra/` Bicep templates (resource group, ACR, Container App, managed identity).
- A service principal with sufficient permissions (see below).

## Required GitHub Secret

Configure under **Settings > Secrets and variables > Actions > Secrets**:

| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | Service principal credentials as a JSON object (see below) |

## Required GitHub Variables

Configure under **Settings > Secrets and variables > Actions > Variables**:

| Variable | Description | Example |
|---|---|---|
| `AZURE_CONTAINER_REGISTRY_NAME` | Name of the Azure Container Registry (not the login server) | `acrmyenvabc123` |
| `AZURE_CONTAINER_APP_NAME` | Name of the Azure Container App | `ca-myenv-abc123` |
| `AZURE_RESOURCE_GROUP` | Name of the resource group containing the Container App | `rg-myenv` |

You can retrieve these values from the Bicep deployment outputs:

```bash
az deployment sub show -n <deployment-name> --query properties.outputs
```

## Service Principal Setup

1. Create a service principal and capture its credentials:

   ```bash
   az ad sp create-for-rbac --name "github-deploy" --role Contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
     --json-auth
   ```

2. Grant **AcrPush** on the container registry:

   ```bash
   az role assignment create --assignee <client-id> --role AcrPush \
     --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ContainerRegistry/registries/<acr-name>
   ```

3. Copy the full JSON output from step 1 and save it as the `AZURE_CREDENTIALS` secret in GitHub. The JSON looks like:

   ```json
   {
     "clientId": "...",
     "clientSecret": "...",
     "subscriptionId": "...",
     "tenantId": "...",
     "resourceManagerEndpointUrl": "..."
   }
   ```
