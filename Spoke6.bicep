param location string = 'ItalyCentral'
param vnetName string = 'VNetSpoke6'
param dnsspoke6 string = 'dns_spoke6'
param subnetName string = 'spoke6-subnet'
param addressSpace string = '10.6.0.0/16'
param subnetAddressPrefix string = '10.6.1.0/24'

resource Vnetspoke6 'Microsoft.Network/virtualNetworks@2023-01-01' = {
  name: spoke6vnet
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



param clusterName string = 'myAKSCluster'

param dnsPrefix string = 'myakscluster'
param servicePrincipalClientId string
param servicePrincipalClientSecret string

resource KubernetesSpoke6 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: 'clusterSpoke6'
  location: location
  properties: {
    kubernetesVersion: '1.26.4' 
    enableRBAC: true
    dnsPrefix: 'dnsspoke6'
    agentPoolProfiles: [
      {
        name: 'agentspoke6'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
    }
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
      secret: servicePrincipalClientSecret
    }
    addonProfiles: {
      kubeDashboard: {
        enabled: true
      }
    }
    tags: {
      environment: 'production'
    }
  }
  
}

output netId string = Vnetspoke6.id
output netPrefixes string = Vnetspoke6.properties.addressSpace.addressPrefixes[0]
output clusterName string = KubernetesSpoke6.name
output clusterUri string = KubernetesSpoke6.properties.endpoint
