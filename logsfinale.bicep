param location string= 'westus'

 resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01'={
  name:'logs'
  location: location
  properties: {
  addressSpace: {
    addressPrefixes: [ '10.1.0.0/20' ]
    }
}
 }
var name = 'elena135533ele'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    virtualNetworkRules: [
      {
        action: 'Allow'
        id: vnet.id
        state: 'string'
      }
    ]
  
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    accessTier: 'Hot'
  }
}

output netId string = vnet.id
output netPrefixes string = vnet.properties.addressSpace.addressPrefixes[0]
