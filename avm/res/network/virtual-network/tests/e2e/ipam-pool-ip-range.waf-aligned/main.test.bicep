targetScope = 'subscription'

metadata name = 'IPAM Pool WAF Aligned'
metadata description = 'This instance deploys the module in alignment with the best-practices of the Well-Architected Framework using an IPAM Pool IP range.'

// ========== //
// Parameters //
// ========== //

/*
  Required Parameters
*/

/*
  Optional Parameters
*/

@description('Optional. A token to inject into the name of each resource.')
param namePrefix string = '#_namePrefix_#'

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'dep-${namePrefix}-network.virtualnetworks-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'nvnipamwaf'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, resourceLocation)}-nestedDependencies'
  params: {
    managedIdentityName: 'dep-${namePrefix}-msi-${serviceShort}'
    routeTableName: 'dep-${namePrefix}-rt-${serviceShort}'
    networkSecurityGroupName: 'dep-${namePrefix}-nsg-${serviceShort}'
    networkSecurityGroupBastionName: 'dep-${namePrefix}-nsg-bastion-${serviceShort}'
    location: resourceLocation
    networkManagerName: 'dep-${namePrefix}-vnm-${serviceShort}'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: resourceLocation
}

// Diagnostics
// ===========
module diagnosticDependencies '../../../../../../../utilities/e2e-template-assets/templates/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, resourceLocation)}-diagnosticDependencies'
  params: {
    storageAccountName: 'dep${namePrefix}diasa${serviceShort}01'
    logAnalyticsWorkspaceName: 'dep-${namePrefix}-law-${serviceShort}'
    eventHubNamespaceEventHubName: 'dep-${namePrefix}-evh-${serviceShort}'
    eventHubNamespaceName: 'dep-${namePrefix}-evhns-${serviceShort}'
    location: resourceLocation
  }
}

// ============== //
// Test Execution //
// ============== //

@batchSize(1)
module testDeployment '../../../main.bicep' = [
  for iteration in ['init', 'idem']: {
    scope: resourceGroup
    name: '${uniqueString(deployment().name, resourceLocation)}-test-${serviceShort}-${iteration}'
    params: {
      addressPrefixes: [
        nestedDependencies.outputs.networkManagerIpamPoolId
      ]
      diagnosticSettings: [
        {
          name: 'customSetting'
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          eventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
          eventHubAuthorizationRuleResourceId: diagnosticDependencies.outputs.eventHubAuthorizationRuleId
          storageAccountResourceId: diagnosticDependencies.outputs.storageAccountResourceId
          workspaceResourceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
        }
      ]
      dnsServers: [
        '10.0.1.4'
        '10.0.1.5'
      ]
      flowTimeoutInMinutes: 20
      ipamPoolNumberOfIpAddresses: '65536'
      location: resourceLocation
      name: '${namePrefix}${serviceShort}001'
      subnets: [
        {
          name: 'GatewaySubnet'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
        }
        {
          name: '${namePrefix}-az-subnet-x-001'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
          networkSecurityGroupResourceId: nestedDependencies.outputs.networkSecurityGroupResourceId
          roleAssignments: [
            {
              roleDefinitionIdOrName: 'Reader'
              principalId: nestedDependencies.outputs.managedIdentityPrincipalId
              principalType: 'ServicePrincipal'
            }
          ]
          routeTableResourceId: nestedDependencies.outputs.routeTableResourceId
          serviceEndpoints: [
            'Microsoft.Storage'
            'Microsoft.Sql'
          ]
        }
        {
          name: '${namePrefix}-az-subnet-x-002'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
          delegation: 'Microsoft.Netapp/volumes'
          networkSecurityGroupResourceId: nestedDependencies.outputs.networkSecurityGroupResourceId
        }
        {
          name: '${namePrefix}-az-subnet-x-003'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
          networkSecurityGroupResourceId: nestedDependencies.outputs.networkSecurityGroupResourceId
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        {
          name: 'AzureBastionSubnet'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
          networkSecurityGroupResourceId: nestedDependencies.outputs.networkSecurityGroupBastionResourceId
        }
        {
          name: 'AzureFirewallSubnet'
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: nestedDependencies.outputs.networkManagerIpamPoolId
              }
              numberOfIpAddresses: '256'
            }
          ]
        }
      ]
      tags: {
        'hidden-title': 'This is visible in the resource name'
        Environment: 'Non-Prod'
        Role: 'DeploymentValidation'
      }
    }
  }
]
