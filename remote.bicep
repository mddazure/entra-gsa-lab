param location string = 'swedencentral'

var clientimagePublisher = 'microsoftwindowsdesktop'
var clientimageOffer = 'windows-11'
var clientimageSku = 'win11-22h2-pro'

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'

var ciscoPublisher = 'cisco'
var ciscoOffer = 'cisco-c8000v-byol'
var ciscoSku = '17_13_01a-byol'

var adminUsername = 'AzureAdmin'
var adminPassword = 'GSA-demo2024'

resource remotevnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'remotevnet'
  location: location
  properties: {
    addressSpace: {
        addressPrefixes: [
          '172.16.0.0/16' 
          'cdef:ab12:3456::/48'
        ]
    }
    subnets: [
      {
        name: 'vmsubnet0'
        properties: {
          addressPrefixes:  [
          '172.16.0.0/24'
          'cdef:ab12:3456::/64'
            ]
          networkSecurityGroup: {
          id: remotensg.id 
          }
          routeTable: {
          id: remoteudr.id
          }
        }
      }
      {
        name: 'c8ksubnet'
        properties: {
          addressPrefixes: [
          '172.16.1.0/24'
          'cdef:ab12:3456:1::/64'
          ]
          networkSecurityGroup: {
          id: remotensg.id 
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
        addressPrefix: '172.16.255.0/24'
        }
      }
    ]
  }
}
resource remoteudr 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'remoteudr'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '172.16.1.4'
          }
        }
    ]
  }
}


resource remotensg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'remotensg'
  location: location
  properties: {
    securityRules: [
      {
      name: 'AllowSSHInbound'
      properties: {
        access: 'Allow'
        description: 'Allow SSH inbound traffic'
        destinationAddressPrefix: '*'
        destinationPortRange: '22'
        direction: 'Inbound'
        priority: 100
        protocol: 'Tcp'
        sourceAddressPrefixes: [
          '217.121.229.32'
        ] 
        sourcePortRange: '*'
        }
      }
      {
        name: 'AllowRDPInbound'
        properties: {
          access: 'Allow'
          description: 'Allow RDP inbound traffic'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          direction: 'Inbound'
          priority: 150
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '217.121.229.32'
          ] 
          sourcePortRange: '*'
          }
        }
    ]
  }
}

resource c8k 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'c8k'
  location: location
  plan:{
    name: '17_13_01a-byol'
    publisher: 'cisco'
    product: 'cisco-c8000v-byol'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: ciscoPublisher
        offer: ciscoOffer
        sku: ciscoSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'c8k'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: c8knic.id
        }
      ]
    }
  }
}
resource c8knic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'c8knic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          subnet: {
            id: '${remotevnet.id}/subnets/c8ksubnet'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: '172.16.1.4'
          publicIPAddress: {
            id: c8kpublicip.id
          }
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          primary: false
          subnet: {
            id: '${remotevnet.id}/subnets/c8ksubnet'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv6'
          privateIPAddress: 'cdef:ab12:3456:1::4'
        }  
      }
    ]
  }
}
resource c8kpublicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'c8kpublicip'
  location: location
  sku:{
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource clientvm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'clientvm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: clientimagePublisher
        offer: clientimageOffer
        sku: clientimageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'clientvm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: clientvmnic.id
        }
      ]
    }
  }
}
resource clientvmnic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'clientvmnic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          subnet: {
            id: '${remotevnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: '172.16.0.4'
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          primary: false
          subnet: {
            id: '${remotevnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv6'
          privateIPAddress: 'cdef:ab12:3456::4'
        }
      }
    ]
  }
}

