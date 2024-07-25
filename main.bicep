param location string = 'swedencentral'


var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'
var clientimagePublisher = 'microsoftwindowsdesktop'
var clientimageOffer = 'windows-11'
var clientimageSku = 'win11-22h2-pro'
var linuximagePublisher = 'Canonical'
var linuximageOffer = 'UbuntuServer'
var linuximageSku = '18.04-LTS'

var adminUsername = 'marc'
var adminPassword = 'Nienke040598'

resource servervnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'servervnet'
  location: location
  properties: {
    addressSpace: {
        addressPrefixes: [
          '10.0.0.0/16' 
          'abcd:de12:3456::/48'
        ]
    }
    subnets: [
      {
        name: 'vmsubnet0'
        properties: {
          addressPrefixes:  [
          '10.0.0.0/24'
          'abcd:de12:3456::/64'
            ]
          networkSecurityGroup: {
          id: servernsg.id 
          }
        }
      }
      {
        name: 'vmsubnet1'
        properties: {
          addressPrefixes: [
          '10.0.1.0/24'
          'abcd:de12:3456:1::/64'
          ]
          networkSecurityGroup: {
          id: servernsg.id 
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
        addressPrefix: '10.0.255.0/24'
        }
      }
    ]
  }
}
resource servernsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'servernsg'
  location: location
  properties: {
    securityRules: [
      {
      name: 'AllowHTTPInbound'
      properties: {
        access: 'Allow'
        description: 'Allow HTTP inbound traffic'
        destinationAddressPrefix: '*'
        destinationPortRange: '80'
        direction: 'Inbound'
        priority: 100
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
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
resource vm1 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: linuximagePublisher
        offer: linuximageOffer
        sku: linuximageSku
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
      computerName: 'vm1'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm1nic.id
        }
      ]
    }
  }
}

resource vm1nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'vm1nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          loadBalancerBackendAddressPools: [
          ]
        }
      }
    ]
  }
}
resource vm2 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: linuximagePublisher
        offer: linuximageOffer
        sku: linuximageSku
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
      computerName: 'vm2'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm2nic.id
        }
      ]
    }
  }
}

resource vm2nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'vm2nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.5'
          loadBalancerBackendAddressPools: [

          ]
        }
      }
    ]
  }
}

resource gsaconnector 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'gsaconnector'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
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
      computerName: 'gsaconnector'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: gsaconnectornic.id
        }
      ]
    }
  }
}

resource gsaconnectornic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'gsaconnectornic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet1'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.4'
        }
      }
    ]
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: 'bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionipconfig'
        properties: {
          publicIPAddress: {
            id: bastionipv4.id
          }
          subnet: {
            id: '${servervnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}
resource bastionipv4 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'bastionipv4'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource lbfepv4 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'lbfepv4'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}
resource lbfepv6 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'lbfepv6'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv6'
  }
}
resource lb 'Microsoft.Network/loadBalancers@2024-01-01'= {
  name: 'lb'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'publicipconfigv4'
        properties: {
          publicIPAddress: {
            id: lbfepv4.id
          }
        }
      }
      {
        name: 'publicipconfigv6'
        properties: {
          publicIPAddress: {
            id: lbfepv6.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bep1'
        properties: {
            loadBalancerBackendAddresses: [
            ] 
          }
      }
    ]
    probes: [
      {
        name: 'probehttp'
        properties: {
          intervalInSeconds: 10
          numberOfProbes: 5
          port: 80
          protocol: 'Http'
          requestPath: '/'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'publicIPLBRulev4'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','lb','bep1')
          }
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations','lb','publicipconfigv4')
          }
          frontendPort: 80
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes','lb','probehttp')
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'publicIPLBRulev6'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','lb','bep1')
          }
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations','lb','publicipconfigv6')
          }
          frontendPort: 80
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes','lb','probehttp')
          }
          protocol: 'Tcp'
        }
      }
    ]
  }
}

resource ilb 'Microsoft.Network/loadBalancers@2024-01-01'= {
  name: 'ilb'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'privateipconfigv4'
        properties: {
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet1'
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'ilbbep1'
        properties: {
            loadBalancerBackendAddresses: [
            ] 
          }
      }
    ]
    probes: [
      {
        name: 'probev4'
        properties: {
          intervalInSeconds: 10
          numberOfProbes: 5
          port: 80
          protocol: 'Http'
          requestPath: '/'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'privateIPhttpRulev4'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','ilb','ilbbep1')
          }
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations','ilb','privateipconfigv4')
          }
          frontendPort: 80
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes','ilb','probev4')
          }
          protocol: 'Tcp'
        }
      }
    ]
  }
}
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: location
  name: 'gsa.local'
}
resource gsaconnectorDNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'gsaconnector'
  properties: {
   aRecords: [
      {
        ipv4Address: gsaconnectornic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
          ]
        }
}
resource vm1DNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'vm1'
  properties: {
   aRecords: [
      {
        ipv4Address: vm1nic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
    ]
  }
}
resource vm2DNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'vm2'
  properties: {
   aRecords: [
      {
        ipv4Address: vm2nic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
    ]
  }
}

output vm1FQDN string = vm1DNSRecordSet.properties.aRecords[0].ipv4Address
output vm2FQDN string = vm2DNSRecordSet.properties.aRecords[0].ipv4Address
output gsaconnectorFQDN string = gsaconnectorDNSRecordSet.properties.aRecords[0].ipv4Address

