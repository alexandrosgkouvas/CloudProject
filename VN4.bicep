param backendAddress1 string = 'apipub6.azurewebsites.net'
param backendAddress2 string = 'Webapplic4.azurewebsites.net'


resource Webapplan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'Webapp'
  location: 'Italy North'
  sku: {
    name: 'S1'
  }
}


resource Webapplic 'Microsoft.Web/sites@2023-12-01' = {
  name: 'Webapplic4'
  location: 'Italy North'
  properties: {
    serverFarmId: Webapplan.id
    httpsOnly: true    
    siteConfig: {
      linuxFxVersion: ''
    }
  }
}


resource APIplan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'APIplan'
  location: 'Italy North'
  sku: {
    name: 'S1'
  } 
}



resource APIpub 'Microsoft.Web/sites@2023-12-01' = {
  name: 'APIpub6'
  location: 'Italy North'
  properties: {
    serverFarmId: APIplan.id
    httpsOnly:true
    siteConfig: {
      linuxFxVersion: ''
    }
  }
}



resource webappstorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  name: 'webappstorage4'
  location: 'italynorth'
  properties: {
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
    }
  }



resource storendpointprivnic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'storendpointpriv.nic'
  properties: {
    ipConfigurations: [
      {
        name: 'privateEndpointIpConfig'
        id: storendpointpriv.id
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '10.4.0.4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: VN.properties.subnets[1].id
          }
          }
        }
    ]
    nicType: 'Standard'
  }
  location: 'italynorth'
}  



  resource storendpointpriv 'Microsoft.Network/privateEndpoints@2024-01-01' = {
    name: 'storendpointpriv'
    location: 'italynorth'
    properties: {
      privateLinkServiceConnections: [
        {
          name: 'conn'
          properties: {
            privateLinkServiceId: webappstorage.id
            groupIds: [
              'blob'
            ]
          }
        }
      ]
      customDnsConfigs: [
        {
          fqdn: 'webappstorage4.blob.environment()'
          ipAddresses: [
            '10.4.0.4'
          ]
        }
      ]
      subnet: {
        id: VN.properties.subnets[1].id
        name:'substorage'
      }

    }
  }
  
  

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2021-05-01' = {
  name: 'ddosProtectionPlan'
  location: 'italynorth'
}



resource VN 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'VN4'
  location: 'italynorth'
  properties: {
      addressSpace: {
      addressPrefixes: [
        '10.4.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subwebapp'
        properties: {
          addressPrefix: '10.4.1.0/24'
          delegations: [
            {
              name: 'delegation'
              id: Webapplic.id
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'substorage'
        properties: {
          addressPrefix: '10.4.0.0/24'
          // privateEndpoints: {
          //     id: storendpointpriv.id
          //   }
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'subAPI'
        properties: {
          addressPrefix: '10.4.2.0/24'
          delegations: [
            {
              name: 'delegation'
              id: APIpub.id
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'subgate'
        properties: {
          addressPrefix: '10.4.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: true
    ddosProtectionPlan: {
      id: ddosProtectionPlan.id
    }
  }
}


resource NSGsubwebapp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'NSGsubwebapp'
  location: 'italynorth'
  properties: {
    securityRules: [
      {
        name: 'DenyWebappToAPI'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.4.1.0/24'
          destinationAddressPrefix: '10.4.2.0/24'
          access: 'Deny'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
    subnets: [
      {
        id: VN.properties.subnets[0].id
      }
    ]
  }
}



resource NSGsubAPI 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'NSGsubAPI'
  location: 'italynorth'
  properties: {
    securityRules: [
      {
        name: 'DenyAPIToWebapp'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.4.2.0/24'
          destinationAddressPrefix: '10.4.1.0/24'
          access: 'Deny'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
    subnets: [
      {
        id: VN.properties.subnets[2].id
      }
    ]
  }
}



resource WafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01' = {
  name: 'WafPolicy'
  location: 'italynorth'
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Disabled'
      mode: 'Prevention'
      requestBodyInspectLimitInKB: 128
      fileUploadEnforcement: true
      requestBodyEnforcement: true
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleGroupOverrides: []
        }
      ]
    }
  }
}



resource IPpublicAPI 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'IPpublicAPI'
  location: 'italynorth'
  properties: {
    ipAddress: '4.232.177.161'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}


resource IPpublicWebApp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'IPpublicWebApp'
  location: 'italynorth'
  properties: {
    ipAddress: '172.213.147.103'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

//Cannot be deployed because Listener HTTPs setting requires a SSL Certification
resource GatewayAPI 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: 'GatewayAPI'
  location: 'italynorth'
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      family: 'Generation_1'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        id: IPpublicAPI.id
        properties: {
          subnet: {
            id: VN.properties.subnets[3].id
          }
        }
      }
    ]
    sslProfiles: [
      {
        name: 'sslpolicy'
        id: 'sslpolicy'
        properties: {
          sslPolicy: {
            policyType: 'Custom'
            minProtocolVersion: 'TLSv1_2'
          }
          }
        }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        id: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: IPpublicAPI.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port01'
        properties: {
          port: 443
          // httpListeners: [
          //   {
          //     id: '/subscriptions/a652e6f5-3adf-4414-b197-e32ea19e3545/resourceGroups/Michaela/providers/Microsoft.Network/applicationGateways/GatewayAPItest/httpListeners/appGatewayHttpListener'
          //   }
          // ]
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'API'
        properties: {
          backendAddresses: [
            {
              fqdn: backendAddress1
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'applicationGatewayName', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'applicationGatewayName', 'port01')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'applicationGatewayName', 'gatewaycert')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'applicationGatewayName', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'applicationGatewayName', 'backendAddressPools')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'applicationGatewayName', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    firewallPolicy: {
      id: WafPolicy.id
    }
  }
}

//Cannot be deployed because Listener HTTPs setting requires a SSL Certification

resource GatewayWebApp 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: 'GatewayWebApp'
  location: 'italynorth'
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        id: IPpublicWebApp.id
        properties: {
          subnet: {
            id: VN.properties.subnets[3].id
          }
        }
      }
    ]
    sslProfiles: [
      {
        name: 'sslpolicy'
        id: 'sslpolicy'
        properties: {
          sslPolicy: {
            policyType: 'Custom'
            minProtocolVersion: 'TLSv1_2'
          }
          }
        }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        id: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: IPpublicWebApp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port01'
        properties: {
          port: 443
          // httpListeners: [
          //   {
          //     id: '/subscriptions/a652e6f5-3adf-4414-b197-e32ea19e3545/resourceGroups/Michaela/providers/Microsoft.Network/applicationGateways/GatewayAPItest2/httpListeners/appGatewayHttpListener'
          //   }
          // ]
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'WebApp'
        properties: {
          backendAddresses: [
            {
              fqdn: backendAddress2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'applicationGatewayName', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'applicationGatewayName', 'port01')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'applicationGatewayName', 'gatewaycert')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'applicationGatewayName', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'applicationGatewayName', 'backendAddressPools')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'applicationGatewayName', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    firewallPolicy: {
      id: WafPolicy.id
    }
  }
}

output netId string = VN.id
output netPrefixes string = VN.properties.addressSpace.addressPrefixes[0]
