/*
  Required Parameters
*/

@description('Required. List of IP address prefixes to be used for the IPAM pool.')
param addressPrefixes array

@description('Required. The name of the Network Manager to create.')
param networkManagerName string

@description('Required. The name of the Bastion Network Security Group to create.')
param networkSecurityGroupBastionName string

@description('Required. The name of the Network Security Group to create.')
param networkSecurityGroupName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the Route Table to create.')
param routeTableName string

/*
  Optional Parameters
*/

@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: managedIdentityName
  location: location
}

resource routeTable 'Microsoft.Network/routeTables@2024-07-01' = {
  name: routeTableName
  location: location
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: networkSecurityGroupName
  location: location
}

resource networkSecurityGroupBastion 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: networkSecurityGroupBastionName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          priority: 150
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowSshOutbound'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowHttpOutbound'
        properties: {
          priority: 130
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

resource networkManager 'Microsoft.Network/networkManagers@2024-07-01' = {
  name: networkManagerName
  location: location
  properties: {
    networkManagerScopes: {
      subscriptions: [
        subscription().id
      ]
    }
  }
}

resource networkManagerIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-07-01' = {
  name: '${networkManagerName}-ipamPool'
  parent: networkManager
  location: location
  properties: {
    displayName: '${networkManagerName}-ipamPool'
    addressPrefixes: addressPrefixes
  }
}

@description('The resource ID of the created Route Table.')
output routeTableResourceId string = routeTable.id

@description('The resource ID of the created Network Security Group.')
output networkSecurityGroupResourceId string = networkSecurityGroup.id

@description('The resource ID of the created Bastion Network Security Group.')
output networkSecurityGroupBastionResourceId string = networkSecurityGroupBastion.id

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the Network Manager.')
output networkManagerId string = networkManager.id

@description('The resource ID of the Network Manager IPAM Pool.')
output networkManagerIpamPoolId string = networkManagerIpamPool.id
