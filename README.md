# Global Secure Access lab
Microsoft's Security Service Edge (SSE) solution is comprised of Entra Internet Access and Entra Private Access, unified under the name [Global Secure Access](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-what-is-global-secure-access). GSA is part of the Microsoft Entra ID portfolio and is operated from the [Entra portal](https://entra.microsoft.com/#home). 

This lab explores both the Private- and Internet Access components of GSA. A backend application, based on Jose Moreno's [Yet Another Demo App (YADA)](https://github.com/Microsoft/YADA), is deployed in a VNET in Azure. Then steps are described to set up Entra Private Access, so that the application is accessible privately from a client without the need for a VPN connection to the VNET. 
The lab then continues to explore Entra Internet Access, demonstrating how to control and secure internet access from remote clients, i.e. clients not connected to the corporate network.

## Prerequisites
Most important prequisite is [Global Secure Access Administrator](https://learn.microsoft.com/en-us/entra/global-secure-access/quickstart-access-admin-center) and [Application Administrator](https://learn.microsoft.com/en-us/entra/global-secure-access/troubleshoot-connectors#verify-admin-is-used-to-install-the-connector) access, or Global Administrator access, to an Entra ID P1 or P2 tenant. GSA is not available under Entra ID Free tenants.

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

Accept terms of use of the Kinvolk Flatcar image:

    az vm image terms accept -p kinvolk -f flatcar-container-linux-free --plan stable-gen2 -o none

Deploy template:

    az deployment group create -g <rgname> --template-file main.bicep --parameters location=<region>

### Verify
The YADA web tier should now be available through the ELB's public endpoints. Obtain both the IPv4 and IPv6 frontend addresses:

    az network public-ip list -g gsa-lab -o table

(Ignore bastionipv4 in the output from above command).

Access the Windows 11 client you intend to use in this lab, and browse to both the IPv4 and IPv6 endpoints (enclose the IPv6 address in square brackets [] when pasting in to the browser's address line).

## Global Secure Access

### Install Private Network Connector
The first step in setting up GSA is to install the Entra Private Network Connector agent on the gsaconnector VM. This VM runs Windows Server 2022 and it does not have to be joined to Entra ID. The role of the connector is to establish an outbound connection to the Microsoft Entra Private Access and application proxy services. This connection then serves as a bidrectional connection path between the application proxy and the applications inside a private network, without needing inbound connectivity from the internet into the private network. This communication path is shown in the above diagram as the green dashed lines.

Log on to the VM named gsaconnector via Bastion.
Username: AzureAdmin
Password: GSA-demo2024 

In Server Manager, set IE Enhanced Security Configuration to Off:

![image](/images/ie-security-off.png)

Browse to 

    https://entra.microsoft.com

and log on with the credentials of a user with the Global Secure Access Administrator and Application Administrator roles in your Entra ID tenant.

In the left-hand pane, scroll down to Global Secure Access and click the carret to open the menu. Scroll further down, click the carret next to Connect to open the submenu and click Connectors. Then click Download connector service at the top of the screen, and Accept terms & Download in the right-hand window.

![image](/images/download_connector.png)

Open the installer when it has downloaded. Sign in with the credentials of your Entra ID user with the Global Secure Access Administrator and Application Administrator roles.

When the Connector has successfully installed, it will connect to Entra and be listed in the Private Network connectors page:

![image](/images/connector_success.png)


