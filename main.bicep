param location string = 'swedencentral'


var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'
var clientimagePublisher = 'microsoftwindowsdesktop'
var clientimageOffer = 'windows-11'
var clientimageSku = 'win11-22h2-pro'
var linuximagePublisher = 'kinvolk'
var linuximageOffer = 'flatcar-container-linux-free'
var linuximageSku = 'stable-gen2'

var api_image='erjosito/yadaapi:1.0'
var web_image='erjosito/yadaweb:1.0'

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
            {id: lb.properties.backendAddressPools[0].id}
            {id: ilb.properties.backendAddressPools[0].id}
          ]
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          privateIPAddressVersion: 'IPv6'
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: 'abcd:de12:3456::4'
          loadBalancerBackendAddressPools: [
            {id: lb.properties.backendAddressPools[1].id}
            {id: ilb.properties.backendAddressPools[1].id}
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
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.5'
          loadBalancerBackendAddressPools: [
            {id: lb.properties.backendAddressPools[0].id}
            {id: ilb.properties.backendAddressPools[0].id}
          ]
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          privateIPAddressVersion: 'IPv6'
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet0'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: 'abcd:de12:3456::5'
          loadBalancerBackendAddressPools: [
            {id: lb.properties.backendAddressPools[1].id}
            {id: ilb.properties.backendAddressPools[1].id}
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
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
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
  sku: {
    name: 'Standard'
  }
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
      {
        name: 'bep2'
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','lb','bep2')
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
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'privateipconfigv4'
        properties: {
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet1'
          }
          privateIPAddress: '10.0.1.100'
          privateIPAllocationMethod: 'Static'
        }
      }
      {
        name: 'privateipconfigv6'
          properties: {
          privateIPAddressVersion: 'IPv6'
          subnet: {
            id: '${servervnet.id}/subnets/vmsubnet1'
          }
          privateIPAddress: 'abcd:de12:3456:1::ff'
          privateIPAllocationMethod: 'Static'
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
      {
        name: 'ilbbep2'
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
      {
        name: 'privateIPhttpRulev6'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools','ilb','ilbbep2')
          }
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations','ilb','privateipconfigv6')
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
  location: 'global'
  name: 'gsa.local'
}
resource gsaconnectorDNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'gsaconnector'
  properties: {
    ttl: 3600
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
    ttl: 3600
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
    ttl: 3600
    aRecords: [
      {
        ipv4Address: vm2nic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
    ]
  }
}
resource vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSZone
  name: 'vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: servervnet.id
      }
      registrationEnabled: false
    }
}



output vm1FQDN string = vm1DNSRecordSet.properties.aRecords[0].ipv4Address
output vm2FQDN string = vm2DNSRecordSet.properties.aRecords[0].ipv4Address
output gsaconnectorFQDN string = gsaconnectorDNSRecordSet.properties.aRecords[0].ipv4Address

