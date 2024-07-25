@description('Location for the acc.')
param location string = resourceGroup().location
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'cosnet'
  location: location 
  properties: {
    addressSpace:{
      addressPrefixes: [ '10.3.0.0/16']
  }
}
}

output vnetId string = vnet.id
output netPrefixes string = vnet.properties.addressSpace.addressPrefixes[0]

