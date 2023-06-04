param name string
param suffix string = ''
param location string = resourceGroup().location
param env string = 'dev'

// Storage
@allowed([
  'Standard_LRS'
  'Standard_ZRS'  
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageAccountSku string = 'Standard_LRS'
// Array item should be in the form of:
// {
//   name: '<container_name>'
//   publicAccess: '<None|Blob|Container>'
// }
param storageAccountBlobContainers array = []
param storageAccountTables array = []

// Log Analytics Workspace
@allowed([
  'Free'
  'Standard'
  'Premium'
  'Standalone'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'CapacityReservation'
])
param workspaceSku string = 'PerGB2018'

// Application Insights
@allowed([
  'web'
  'other'
])
param appInsightsType string = 'web'

@allowed([
  'ApplicationInsights'
  'ApplicationInsightsWithDiagnosticSettings'
  'LogAnalytics'
])
param appInsightsIngestionMode string = 'LogAnalytics'

// Consumption Plan
param consumptionPlanIsLinux bool = false

// Function App
@allowed([
  'Development'
  'Staging'
  'Production'
])
param functionEnvironment string = 'Production'
@allowed([
  'v3'
  'v4'
])
param functionExtensionVersion string = 'v4'
@allowed([
  'dotnet'
  'dotnet-isolated'
  'java'
  'node'
  'python'
  'poweshell'
])
param functionWorkerRuntime string = 'dotnet'
@allowed([
  // dotnet / dotnet-isolated
  'v6.0'
  'v7.0'
  // java
  'v8'
  'v11'
  'v17'
  // node.js
  'v12'
  'v14'
  'v16'
  'v18'
  // python
  'v3.7'
  'v3.8'
  'v3.9'
  'v3.10'
  'v3.11'
  // powershell
  'v7'
])
param functionWorkerVersion string = 'v6.0'

module st './storageAccount.bicep' = {
  name: 'FunctionApp_StorageAccount_${suffix}'
  params: {
    name: name
    suffix: suffix
    location: location
    env: env
    storageAccountSku: storageAccountSku
    storageAccountBlobContainers: storageAccountBlobContainers
    storageAccountTables: storageAccountTables
  }
}

module wrkspc './logAnalyticsWorkspace.bicep' = {
  name: 'LogAnalyticsWorkspace_FunctionApp_${suffix}'
  params: {
    name: name
    suffix: suffix
    location: location
    env: env
    workspaceSku: workspaceSku
  }
}

module appins './appInsights.bicep' = {
  name: 'ApplicationInsights_FunctionApp_${suffix}'
  params: {
    name: name
    suffix: suffix
    location: location
    env: env
    appInsightsType: appInsightsType
    appInsightsIngestionMode: appInsightsIngestionMode
    workspaceId: wrkspc.outputs.id
  }
}

module csplan './consumptionPlan.bicep' = {
  name: 'ConsumptionPlan_FunctionApp_${suffix}'
  params: {
    name: name
    suffix: suffix
    location: location
    env: env
    consumptionPlanIsLinux: consumptionPlanIsLinux
  }
}

module fncapp './functionApp.bicep' = {
  name: 'FunctionApp_FunctionApp_${suffix}'
  params: {
    name: name
    suffix: suffix
    location: location
    env: env
    storageAccountId: st.outputs.id
    storageAccountName: st.outputs.name
    appInsightsId: appins.outputs.id
    consumptionPlanId: csplan.outputs.id
    functionIsLinux: consumptionPlanIsLinux
    functionEnvironment: functionEnvironment
    functionExtensionVersion: functionExtensionVersion
    functionWorkerRuntime: functionWorkerRuntime
    functionWorkerVersion: functionWorkerVersion
  }
}
