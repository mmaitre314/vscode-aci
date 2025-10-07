param name string
param location string
param serviceTag string

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: serviceTag != '' ? [ { ipTagType: 'FirstPartyUsage', tag: serviceTag } ] : []
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: name
  location: location
  properties: {
    securityRules: []
  }
}

resource nat 'Microsoft.Network/natGateways@2024-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: 'aci'
        properties: {
          addressPrefix: '10.0.0.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: { id: nsg.id }
          natGateway: { id: nat.id }
          delegations: [
            {
              name: 'Microsoft.ContainerInstance/containerGroups'
              properties: { serviceName: 'Microsoft.ContainerInstance/containerGroups' }
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
