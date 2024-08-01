# Global Secure Access lab
Microsoft's Security Service Edge (SSE) solution is comprised of Entra Internet Access and Entra Private Access, unified under the name [Global Secure Access](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-what-is-global-secure-access). GSA is part of the Microsoft Entra ID portfolio and is operated from the [Entra portal](https://entra.microsoft.com/#home). 

This lab explores both the Private- and Internet Access components of GSA. A backend application, based on Jose Moreno's [Yet Another Demo App (YADA)](https://github.com/Microsoft/YADA), is deployed in a VNET in Azure. Then steps are described to set up Entra Private Access, so that the application is accessible privately from a client without the need for a VPN connection to the VNET. 
The lab then continues to explore Entra Internet Access, demonstrating how to control and secure internet access from remote clients, i.e. clients not connected to the corporate network.

## Prerequisites
Most important prequisite is [Global Secure Access Administrator access](https://learn.microsoft.com/en-us/entra/global-secure-access/quickstart-access-admin-center) or Global Administrator access to an Entra ID P1 or P2 tenant. GSA is not available under Entra ID Free tenants.

Client device(s) must run 64-bit versions of Windows 11 or Windows 10. The client must be either Microsoft Entra joined or Microsoft Entra hybrid joined to the same tenant that GSA is configured on. As this will usually not be the corporate tenant that your laptop is joined to, the most pragmatic way forward is to [run Windows 11 on a nested virtual machine](https://techcommunity.microsoft.com/t5/itops-talk-blog/how-to-run-a-windows-11-vm-on-hyper-v/ba-p/3713948).

An Azure subscription is required to deploy the backend application. This subscription does not have under the same tenant that GSA is configured on.

## Backend application
The lab backend deployed to Azure comprises following components:

- One Virtual Network.
- Two VMs running the YADA web tier, behind both and an Internal and an External Load Balancer.
- One VM running the YADA application tier.
- One VM running Windows Server, this will be used to install the GSA Connector.
- A Pivate DNS Zone linked to the VNET, with A (IpV4) and AAAA (IPv6) records for the ILB frontend and each of the VMs.

![image](/images/entra-gsa-lab.png)

### Deploy
Log in to Azure Cloud Shell at https://shell.azure.com/ and select Bash.

Ensure Azure CLI and extensions are up to date:
  
    az upgrade --yes
  
If necessary select your target subscription:
  
    az account set --subscription <Name or ID of subscription>

Clone the  GitHub repository: 

    git clone https://github.com/mddazure/entra-gsa-lab

Change directory:
  
    cd ./entra-gsa-lab

Create Resource Group:

    az group create -l <region> -n <rgname>

Deploy template:

    az deployment group create -g <rgname> --template-file main.bicep --parameters location=<region>

### Verify





