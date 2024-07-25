var osDiskType = 'StandardSSD_LRS'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('virtual network for developers and testers')
resource devEnv 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'devEnv'
  location: 'francecentral'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.5.0.0/23'
      ]
    }
    subnets: [
      {
        name: 'devEnv'
        properties: {
          addressPrefix: '10.5.0.0/25'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'testEnv'
        properties: {
          addressPrefix: '10.5.0.128/26'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}



@description('tester`s SSH VM key')
resource testVMkey 'Microsoft.Compute/sshPublicKeys@2024-03-01' = {
  name: 'testVM_key'
  location: 'francecentral'
  tags: {}
  properties: {
    publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6vvYFvQadTwy1hqYx0ivQHUzvrfdzgLW+XI57syP5P generated-by-azure'
  }
}

@description('tester`s network security group')
resource testvmz 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'testvm504_z1'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '10.5.0.132'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: devEnv.properties.subnets[1].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: testVMnsg.id
    }
    
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
  location: 'francecentral'
}

@description('tester`s security group')
resource testVMnsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'testVM-nsg'
  location: 'francecentral'
  properties: {
    securityRules: [
      {
        name: 'SSH'
        id: testVMkey.id 
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'in_from_devs'
        id: testVMkey.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          access: 'Deny'
          priority: 500
          protocol: '*'
          sourceAddressPrefix: '10.5.0.0/25'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.5.0.128/26'
          destinationPortRange: '*'
          direction: 'Inbound'
        }   
      }
      {
        name: 'out_to_devs'
        id: testVMkey.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          access: 'Deny'
          priority: 500
          protocol: '*'
          sourceAddressPrefix: '10.5.0.128/26'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.5.0.0/25'
          destinationPortRange: '*'
          direction: 'Outbound'
        }   
      }
    ]
    
  }
}

@description('tester`s VM')
resource testVM 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'testVM'
  location: 'francecentral'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ls'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'testVM_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: 'testVM'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6vvYFvQadTwy1hqYx0ivQHUzvrfdzgLW+XI57syP5P generated-by-azure'
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: testvmz.id 
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  zones: [
    '1'
  ]
}

//////////////////////////////////////////////
//////////////////DEVELOPERS/////////////////
////////////////////////////////////////////

@description('developer`s ssh vm key')
resource devVMkey 'Microsoft.Compute/sshPublicKeys@2024-03-01' = {
  name: 'devVM_key'
  location: 'francecentral'
  tags: {}
  properties: {
    publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEOFhYL78KmW8e+HgDZZP5qfWhVRTMVhFxr1kH4qfPL generated-by-azure'
  }
}

@description('developer`s network security group')
resource devVMnsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'devVM-nsg'
  location: 'francecentral'
  properties: {
    securityRules: [
      {
        name: 'SSH'
        id: devVMkey.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'to_testers'
        id: testVMkey.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          access: 'Deny'
          priority: 500
          protocol: '*'
          sourceAddressPrefix: '10.5.0.0/25'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.5.0.128/26'
          destinationPortRange: '*'
          direction: 'Outbound'
        }   
      }
      {
        name: 'from_testers'
        id: testVMkey.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          access: 'Deny'
          priority: 500
          protocol: '*'
          sourceAddressPrefix: '10.5.0.128/26'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.5.0.0/25'
          destinationPortRange: '*'
          direction: 'Inbound'
        }   
      }
    ]
  }
}

@description('developer`s network interface')
resource devVMz 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'devVM532_z1'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '10.5.0.4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: devEnv.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: devVMnsg.id
    }
    
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
  location: 'francecentral'
}



@description('developer`s VM')
resource devVM 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'devVM'
  location: 'francecentral'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
   
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'devVM_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: 'devVM'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEOFhYL78KmW8e+HgDZZP5qfWhVRTMVhFxr1kH4qfPL generated-by-azure'
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: devVMz.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  zones: [
    '1'
  ]
}


// /////////////////////////////////////////////
// ////////STORAGE ACCOUNT + FILESHARE/////////
// ///////////////////////////////////////////

param dnsName string = 'privatelink.file.${environment().suffixes.storage}'
param fileName string = 'storeloc.file.${environment().suffixes.storage}'

@description('private link DNS')
resource privatelinkfilecorewindowsnet 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsName
  location: 'global'
}


@description('storage account for fileshare')
resource storeloc 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'storeloctester'
  location: 'francecentral'
  tags: {}
  sku: {
    name: 'Standard_RAGRS'
    // tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}


@description('private endpoint for fileshare')
resource fileshare 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'fileshare'
  location: 'francecentral'
  tags: {}
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'fileshare'
        properties: {
          privateLinkServiceId: storeloc.id
          groupIds: [
            'file'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: devEnv.properties.subnets[1].id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}
