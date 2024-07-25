module spoke1 'logsfinale.bicep' = {
  name: 'logs-Vnet'
}

module spoke2 'spoke2.bicep' = {
  name: 'database'
}

module spoke3 'module.bicep' = {
  name: 'meeting'
}

module spoke4 'VN4.bicep' = {
  name: 'webApp'
}

module spoke5 'spoke5.bicep' = {
  name: 'devs-Vnet'
}

module spoke6 'Spoke6.bicep' = {
  name: 'kubernetes'
}


@description('Hub vnet')
resource hub 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'hub'
  location: 'francecentral'
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: true
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefixes: [
            '10.0.0.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefixes: [
            '10.0.1.64/26'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefixes: [
            '10.0.2.0/26'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    enableDdosProtection: false
  }
}

@description('bastion public IP')
resource bastionIP 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'bastionIP'
  location: 'francecentral'
  zones: [
    '1'
  ]
  properties: {
    ipAddress: '4.233.208.25'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}



@description('hubBastion')
resource hubBastion 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: 'hub-Bastion'
  location: 'francecentral'
  tags: {}
  properties: {
    dnsName: 'bst-2a3a21bf-bed7-477e-afa9-b7a7436c8287.bastion.azure.com'
    scaleUnits: 2
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionIP.id
          }
          subnet: {
            id: hub.properties.subnets[1].id
          }
        }
      }
    ]
  }
  sku: {
    name: 'Basic'
  }
}




resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01'={
  name: 'publicIP'
  location: 'francecentral'
  zones: [
    '1'
  ]
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}



@description('hub firewall policy')
resource hubFirewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: 'hubFirewall'
  location: 'francecentral'
  tags: {}
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}


@description('hub firewall')
resource hubFirewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: 'hubFirewall'
  location: 'francecentral'
  tags: {}
  zones: [
    '1'
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {}
    ipConfigurations: [
      {
        name: 'ipConf'
        properties: {
          publicIPAddress: {
            id: publicIpAddress.id
          }
          subnet: {
            id: hub.properties.subnets[2].id
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: hubFirewallPolicy.id
    }
  }
}

////////////////////////////
///////////PEERINGS////////
//////////////////////////
resource hubToLogs 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer1'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToLog'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke1.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'LogToHub'
    ]
    remoteVirtualNetwork: {
      id: spoke1.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke1.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}

resource hubToDatabase 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer2'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToDatabase'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke2.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'databaseToHub'
    ]
    remoteVirtualNetwork: {
      id: spoke2.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke2.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}

resource hubToMeetings 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer3'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToMeetings'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke3.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'meetingsToHubs'
    ]
    remoteVirtualNetwork: {
      id: spoke3.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke3.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}

resource hubToWebApp 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer4'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToWebApp'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke4.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'webAppToHub'
    ]
    remoteVirtualNetwork: {
      id: spoke4.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke4.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}


resource hubToDev 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer5'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToDev'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke5.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'devToHub'
    ]
    remoteVirtualNetwork: {
      id: spoke5.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke5.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}


resource hubToKub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer6'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    enableOnlyIPv6Peering: false
    localAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    localSubnetNames: [
      'hubToKub'
    ]
    localVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    peerCompleteVnets: true
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteAddressSpace: {
      addressPrefixes: [
        spoke6.outputs.netPrefixes
      ]
    }
    remoteSubnetNames: [
      'kubToHub'
    ]
    remoteVirtualNetwork: {
      id: spoke6.outputs.netId
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        spoke6.outputs.netPrefixes
      ]
    }
    useRemoteGateways: false
  }
}


