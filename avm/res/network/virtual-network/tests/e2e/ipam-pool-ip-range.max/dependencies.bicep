/*
  Required Parameters
*/

@description('Required. List of IP address prefixes to be used for the IPAM pool.')
param addressPrefixes array

@description('Required. The name of the Network Manager to create.')
param networkManagerName string

/*
  Optional Parameters
*/

@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

resource networkManager 'Microsoft.Network/networkManagers@2024-07-01' = {
  location: location
  name: networkManagerName
  properties: {
    networkManagerScopes: {
      subscriptions: [
        subscription().id
      ]
    }
  }
}

resource networkManagerIpamPool 'Microsoft.Network/networkManagers/ipamPools@2024-07-01' = {
  parent: networkManager
  location: location
  name: '${networkManagerName}-ipamPool'
  properties: {
    addressPrefixes: addressPrefixes
    displayName: '${networkManagerName}-ipamPool'
  }
}

@description('The resource ID of the Network Manager.')
output networkManagerId string = networkManager.id

@description('The resource ID of the Network Manager IPAM Pool.')
output networkManagerIpamPoolId string = networkManagerIpamPool.id
