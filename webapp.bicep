@description('Location for the acc.')
param location string = resourceGroup().location




//Creating the App Service
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'meetingsplan'
  location: location
  sku:{
    name: 'S1'
  }
}

resource webapp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'meetingsweb'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    publicNetworkAccess: 'Disabled'
    httpsOnly: true
    }
  }
 