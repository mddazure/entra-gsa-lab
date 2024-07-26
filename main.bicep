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

var sql_server_fqdn = 'yada-db-server.database.windows.net'
var sql_username = 'marc'
var sql_password = 'Nienke040598'

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
resource web1 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'web1'
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
      computerName: 'web1'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: web1nic.id
        }
      ]
    }
  }
}

resource web1nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'web1nic'
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
/*resource web1runcommand 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: web1
  name: 'web1runcommand'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/erjosito/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.sh'
      ]
      commandToExecute: 'bash azuredeploy.sh'
    }
  }
}*/

resource web1runcommand 'Microsoft.Compute/virtualMachines/runCommands@2024-03-01' = {
  parent: web1
  name: 'web1runcommand'
  location: location
  properties: {
    source: {
      script: 'docker run --restart always -d -p 80:80 -e "API_URL=http://${apinic.properties.ipConfigurations[0].properties.privateIPAddress}:8080" --name yadaweb ${web_image}'
    }
  }
}

resource web2 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'web2'
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
      computerName: 'web2'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: web2nic.id
        }
      ]
    }
  }
}

resource web2nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'web2nic'
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

resource api 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'api'
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
      computerName: 'api'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: apinic.id
        }
      ]
    }
  }
}

resource apinic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'apinic'
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
/*resource apiruncommand 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: api
  name: 'apiruncommand'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/erjosito/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.sh'
      ]
      commandToExecute: 'bash azuredeploy.sh'
    }
  }
}*/

resource apiruncommand 'Microsoft.Compute/virtualMachines/runCommands@2024-03-01' = {
  parent: api
  name: 'apiruncommand'
  location: location
  properties: {
    source: {
      script: 'docker run --restart always -d -p 8080:8080 -e "SQL_SERVER_FQDN=${sql_server_fqdn}" -e "SQL_SERVER_USERNAME=${sql_username}" -e "SQL_SERVER_PASSWORD=${sql_password}" --name api ${api_image}'
    }
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
resource web1DNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'web1'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: web1nic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
    ]
  }
}
resource web2DNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'web2'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: web2nic.properties.ipConfigurations[0].properties.privateIPAddress
      }      
    ]
  }
}
resource apiDNSRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDNSZone
  name: 'api'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: apinic.properties.ipConfigurations[0].properties.privateIPAddress
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



output web1FQDN string = web1DNSRecordSet.properties.aRecords[0].ipv4Address
output web2FQDN string = web2DNSRecordSet.properties.aRecords[0].ipv4Address
output gsaconnectorFQDN string = gsaconnectorDNSRecordSet.properties.aRecords[0].ipv4Address
