
@description('DB acc name, max length 44.')
@maxLength(44)
param accountName string = 'cosmosformeetingsapp'

@description('Location for the acc.')
param location string = resourceGroup().location

@description('primary region.')
param primaryRegion string = location


@description('secondary region.')
param secondaryRegion string = 'westeurope'

@description('Database Name')
param databaseName string = 'ourdatabase'

@description('Container Name')
param containerName string = 'container'

@description('The throughput for the container')
param throughput int = 500

var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: true
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

//Creating the Cosmos DB Account
resource account 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    backupPolicy: {
      type: 'Continuous' 
      continuousModeProperties: {
        tier:'Continuous7Days'
      }
    }
    consistencyPolicy: {
      defaultConsistencyLevel: 'Strong'}
    databaseAccountOfferType:'Standard'
    locations: locations
  }
}
//Creating the Cosmos DB Database and container
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' ={
  parent: account
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}
resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: []
      }
    }
    options: {
      throughput: throughput
    }
  }
}

output connectionstring string = account.properties.documentEndpoint
