param serverspoke2_name string = 'server2spoke'
param virtualNetworkName string = 'vnetspoke2' 
param subnetName string = 'Subnetspoke2' 
param privateEndpointName string = 'Endpointspoke2'
//Create the server for the Spoke2
resource serverdb_spoke2 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: 'serverspoke2/db2'
  location: 'francecentral'
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1 // 2 
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    readScale: 'Disabled'
    autoPauseDelay: 60
    requestedBackupStorageRedundancy: 'Local' // 'Geo' 
    availabilityZone: 'NoPreference'
  }
}

resource serverspoke2_name_db2_ 'Microsoft.Sql/servers/databases/advancedThreatProtectionSettings@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_CreateIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'CreateIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_DbParameterization 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'DbParameterization'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_DefragmentIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'DefragmentIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_DropIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'DropIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_ForceLastGoodPlan 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'ForceLastGoodPlan'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingPolicies_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/auditingPolicies@2014-04-01' = {
  parent: serverdb_spoke2
  name: 'Default'
  location: 'France Central'
  properties: {
    auditingState: 'Disabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingSettings_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/auditingSettings@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_backupLongTermRetentionPolicies_servers_server2spoke_name_db2_default 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'default'
  properties: {
    weeklyRetention: 'PT0S'
    monthlyRetention: 'PT0S'
    yearlyRetention: 'PT0S'
    weekOfYear: 0
  }
}

resource Microsoft_Sql_servers_databases_backupShortTermRetentionPolicies_servers_server2spoke_name_db2_default 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'default'
  properties: {
    retentionDays: 7
    diffBackupIntervalInHours: 12
  }
}

resource Microsoft_Sql_servers_databases_extendedAuditingSettings_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/extendedAuditingSettings@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_geoBackupPolicies_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/geoBackupPolicies@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_server2spoke_name_db2_Current 'Microsoft.Sql/servers/databases/ledgerDigestUploads@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Current'
  properties: {}
}

resource Microsoft_Sql_servers_databases_securityAlertPolicies_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/securityAlertPolicies@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Default'
  properties: {
    state: 'Disabled'
    disabledAlerts: [
      ''
    ]
    emailAddresses: [
      ''
    ]
    emailAccountAdmins: false
    retentionDays: 0
  }
}

resource Microsoft_Sql_servers_databases_transparentDataEncryption_servers_server2spoke_name_db2_Current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Current'
  properties: {
    state: 'Enabled'
  }
}

resource Microsoft_Sql_servers_databases_vulnerabilityAssessments_servers_server2spoke_name_db2_Default 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2023-08-01-preview' = {
  parent: serverdb_spoke2
  name: 'Default'
  properties: {
    recurringScans: {
      isEnabled: false
      emailSubscriptionAdmins: true
    }
  }
}

//vnet
resource net 'Microsoft.Network/virtualNetworks@2024-01-01'={
  name: virtualNetworkName
  location: 'francecentral'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/23'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.2.0.0/25'
        }
    
      }
    ]
  }
}

//private endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: '${virtualNetworkName}-privateEndpoint'
  location: 'francecentral'
  properties: {
    subnet: {
      id: subnetName
    }
    privateLinkServiceConnections: [
      {
        name: 'privateendpointspoke2'
        properties: {
          privateLinkServiceId: serverspoke2_name//'/subscriptions/952042f3-3081-422f-91cf-dd177fcf675f/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
          groupIds: [
            serverspoke2_name
          ]
        }
      }
    ]
  }
}
//Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointName}-zoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sqlServerDnsZoneConfig'
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', 'privatelink.database.windows.net')
        }
      }
    ]
  }
}

output netId string = net.id
output netPrefixes string = net.properties.addressSpace.addressPrefixes[0]
