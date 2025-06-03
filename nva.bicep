param nvaVMNic_name string
param nvaNSG_name string
param nvaPublicIP_name string
param nva_name string
param vnet_name string
param routeTable_name string = 'nva-route-table'
@secure()
param nva_password string
param nva_username string
param location string = 'eastus'


resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  location: location
  name: nvaNSG_name
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  location: location
  name: nvaPublicIP_name
  properties: {
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource virtualNetworks 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  location: location
  name: vnet_name
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: 'dmzsubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeTable.id
          }
        }
      }
      {
        name: 'workload-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
}

resource virtualMachines'Microsoft.Compute/virtualMachines@2023-09-01' = {
  location: location
  name: nva_name
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces.id
        }
      ]
    }
    osProfile: {
      adminUsername: nva_username
      adminPassword: nva_password
      allowExtensionOperations: true
      computerName: nva_name
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          assessmentMode: 'ImageDefault'
          patchMode: 'ImageDefault'
        }
        provisionVMAgent: true
      }
     
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      imageReference: {
        offer: '0001-com-ubuntu-server-jammy'
        publisher: 'Canonical'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Detach'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        name: '${nva_name}_OSDisk'
        osType: 'Linux'
      }
    }
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-06-01' = {
  name: routeTable_name
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4' // Assuming the NVA will have this IP
        }
      }
    ]
  }
}

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  location: location
  name: nvaVMNic_name
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfignva'
        properties: {
          primary: true
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          publicIPAddress: {
            id: publicIPAddresses.id
          }
          subnet: {
            id: '${virtualNetworks.id}/subnets/dmzsubnet'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroups.id
    }
    nicType: 'Standard'
  }
}
