param vmCount int = 2

param adminUsername string = 'Server-test'
@minLength(12)
@secure()
param adminPassword string
param dnsLabelPrefix string = toLower('${'infinion-server'}-${uniqueString(resourceGroup().id, 'infinion-server')}')
param publicIpName string = 'Dev-IP'
param publicIPAllocationMethod string = 'Dynamic'

param publicIpSku string = 'Standard'

param OSVersion string = '2022-datacenter-azure-edition'
param vmSize string = 'Standard_D2s_v5'
param location string = resourceGroup().location

var numberOfVMs = 2
var nicName = 'InfinionNic'
var addressPrefix = '10.0.0.0/16'
var virtualNetworkName = 'InfinionVN'

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    
  }
}
resource nic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIp.id
          }
          
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}


resource VM 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(1, numberOfVMs) : {
  name: format('infinion-server-{1}', i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: format('infinion-server-{1}', i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
]


output hostname string = publicIp.properties.dnsSettings.fqdn
