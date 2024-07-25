param location string = 'CentralItaly'
param vnetName string = 'VNetSpoke6'
param spoke6Cluster string = 'myAKSCluster'
param subnetName string = 'spoke6-subnet'
param addressSpace string = '10.0.0.0/16'
param subnetAddressPrefix string = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource kubspoke2 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: spoke6Cluster
  location: location
  properties: {
    kubernetesVersion: '1.24.0'
    dnsPrefix: spoke6Cluster
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
        vnetSubnetID: vnet.properties.subnets[0].id
      }
    ]
    linuxProfile: {
      adminUsername: 'spoke6user'
      ssh: {
        publicKeys: [
          {
            keyData: 'spoke6key'
          }
        ]
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
    }
  }
}
output netId string = vnet.id
output netPrefixes string = vnet.properties.addressSpace.addressPrefixes[0]
