# ***Global Secure Access lab***
Microsoft's Security Service Edge (SSE) solution is comprised of Entra Private Access and Entra Internet Access, unified under the name Global Secure Access.

Global Secure Access (GSA) is part of the Microsoft Entra ID portfolio and is operated from the [Entra portal](https://entra.microsoft.com/#home). 

GSA is a complex, multi-faceted service. It can be daunting to experiment with and describe and demonstrate to customers when starting from scratch. This article  consolidates information from the extensive documentation on [Microsoft Learn](https://learn.microsoft.com/en-us/entra/global-secure-access/) and provides a relatively easy to use platform for experimentation and self-learning. 

# Scenario

## Private access
A backend application, based on Jose Moreno's [Yet Another Demo App (YADA)](https://github.com/Microsoft/YADA), is deployed on VMs in a VNET and exposed through an Internal Load Balancer.
We want the application to be available to all users registered in our Entra ID tenant, without the need for a network connection from user's devices to the VNET. The application is accessible via an internal FQDN that resolves to the internal IP address of the ILB. 

We also want to provide SSH console access to the application's VMs to only our global secure access administrator user, again without a network connection between the user's device and the VNET.
## Internet access
The lab then continues to explore Entra Internet Access, demonstrating how to control and secure internet access from user devices, again without a connection to the corporate network.
## Remote network
Finally a Remote network, simulated through an additional VNET, is deployed and connected to the GSA service through VPN. This demonstrates how clients within a private remote network can leverage Entra GSA without the need to have the GSA Client installed.
# Prerequisites
Most important prequisite is to have a user with *both* [Global Secure Access Administrator](https://learn.microsoft.com/en-us/entra/global-secure-access/quickstart-access-admin-center) *and* [Application Administrator](https://learn.microsoft.com/en-us/entra/global-secure-access/troubleshoot-connectors#verify-admin-is-used-to-install-the-connector) access, or Global Administrator access, to an Entra ID P1 or P2 tenant. GSA is not available under Entra ID Free tenants.

Client device(s) must run 64-bit versions of Windows 11 or Windows 10. The client must be either Microsoft Entra joined or Microsoft Entra hybrid joined to the same tenant that GSA is configured on. As this will usually not be the corporate tenant that your laptop is joined to, the most pragmatic way forward is to [run Windows 11 on a nested virtual machine](https://techcommunity.microsoft.com/t5/itops-talk-blog/how-to-run-a-windows-11-vm-on-hyper-v/ba-p/3713948).

An Azure subscription is required to deploy the backend application. This subscription does not have to be under the same tenant that GSA is configured on.

# Backend application
The lab backend deployed to Azure comprises following components:

- One Virtual Network.
- Two VMs running the YADA web tier, behind both and an Internal and an External Load Balancer.
- One VM running the YADA application tier.
- One VM running Windows Server, this will be used to install the GSA Connector.
- A Private DNS Zone linked to the VNET, with A (IpV4) and AAAA (IPv6) records for the ILB frontend and each of the VMs.

![image](/images/entra-gsa-lab.png)

## Deploy
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

## Verify
The YADA web tier should now be available through the ELB's public endpoints. Obtain both the IPv4 and IPv6 frontend addresses:

    az network public-ip list -g gsa-lab -o table

(Ignore bastionipv4 in the output from above command).

Access the Windows 11 client you intend to use in this lab, and browse to both the IPv4 and IPv6 endpoints (enclose the IPv6 address in square brackets [] when pasting in to the browser's address line).

# Global Secure Access

## Install Private Network Connector
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

You can now disconnect from the gsaconnector VM.

## Install Client 
Next is the installation of the [Global Secure Access client](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-install-windows-client) on a client machine. The client machine must run a 64-bit version of Windows 10 or 11 and must be joined to Entra ID. 

:point_right: A convenient method to obtain a self-contained client machine for testing is to install a nested VM running Windows 11 on your primary device. Instructions are [here](/hyper-v.md). 

:point_right: Switching between users on the same client machine does not seem to work smoothly. It appears that the GSA client retains the previous user's profile for a while, before converging on the current user's profile.
When experimenting with multiple users with different profile settings, it is more convenient to use multiple client machines (i.e. multiple VMs) side-by-side.

:point_right: When using a nested VM on a corporate laptop, be aware that Virtual machines where both the host and guest Operating Systems have the Global Secure Access client installed [are not supported](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-install-windows-client#known-limitations).

:point_right: When logging in to a nested VM in Hyper-V, you may see a message saying you need the right to sign in via Remote Desktop Services. When this happens, change to Basic session in the Remote Desktop client by clicking the screen icon at the top

![image](/images/switch_to_basic_session.png)

On the client machine, sign in to the [Entra admin center](https://entra.microsoft.com/) as an Entra user that has the Global Secure Access Administrator role. 

Browse to Global Secure Access > Connect > Client download.

Select Client download.

![images](/images/download_client.png)

Run GlobalSecureAccessClient.exe and accept the terms.

Sign in with the same Entra ID user that you are logged into the VM as, when asked.

The Client will connect to Entra and the icon in the taskbar will show a green tick mark. 
Left clicking the icon shows clients status, right clicking the icon shows menu options.

![images](/images/client_ok.png)

![images](/images/client_status.png)

## Configure GSA
Entra [Private Access](https://learn.microsoft.com/en-us/entra/global-secure-access/concept-private-access) allows remote users to access internal, i.e. non-internet exposed, applications. Private Access allows administrators to specify applications by internally resolvable FQDNs or private IP addresses. Remote users then don't need a VPN to access these resources if they have the Global Secure Access Client installed. The client quietly and seamlessly connects them to the resources they need.
### Private Access
Private Access is controlled by the Private access profile under Traffic forwarding. 

When Enabled (1), the profile applies to all or selected Users and/or groups (2). Private access policies (3) then determine the specific private resources (applications) that the policy controls access to. 

![images](/images/private_access_hierarchy.png)

![images](/images/private_access_profile.png)

Private resources can be defined as either Quick Access, which is a collection of private resources that applies to all or a subset of Users and groups that the Private access policy applies to, or as individual Applications, which allows for narrower control of access to a subset of Users and groups that the Private access policy applies to.

![images](/images/private_access_traffic_policies.png)

#### Private Web access to Yada
We will first configure a Private Access policy to allow all users in the Entra ID tenant to access the web application privately (i.e. not via a public endpoint). This is achieved easiest through [Quick Access](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-configure-quick-access), which configures application access that applies to all users in the Entra tenant.

The web application is behind an Internal Load Balancer, and the ILB front-end address has A (IPv4) and AAAA (IPv6) records named `yada` in the Private DNS Zone `gsa.local`.

Log in to the [Entra admin center ](https://entra.microsoft.com/) as a user with both the Global Secure Access Administrator and Application Administrator roles.

In the left pane, scroll down to Global Secure Access, then click Applications and Quick Access. Name the application Yada, leave Connector Group as Default and click +Add Quick Access application segment.

In the panel appearing on the right, select Destination type as Fully qualified domain name. Then enter `yada.gsa.local` as the FQDN, enter 80 for Ports, leave Protocol as TCP and click Apply. In the main screen click Save.

![image](images/quick_access.png)

:question: Quick Access applications should be accessible to all users in the tenant without further configuration. However, testing at the time of this writing in August 2024 shows that users must still be specifically added to the Enterprise application created by  the Quick Access configuration.

Navigate to the Enterprise appliction, click Users and groups and add individual users.

![images](/images/add_users_to_quick_access.png)

Log on to your client device as one of your normal users and browse to `yada.gsa.local`.

You should now see the Yada application home page. Scroll down to Your IP address. Note that the application sees the request sourced from the gsaconnector vm at 10.0.1.4.

![images](/images/your_ip_address.png)

#### Private SSH administrator access
Now configure SSH access to the individual VMs specifically for the administrator user only.

Navigate to Enterprise applications and name the application `ssh`. Then Add application segments for `web1.gsa.local`,`web2.gsa.local` and `api.gsa.local`, on TCP port 22.

![images](/images/ssh_access.png)

Then navigate to the Enterpise application named SSH, click Users and groups, and add the administrator user.

![images](/images/add_gsaadmin_to_ssh.png)

Open a command prompt and ssh to a one of the vm's as the *local* administrator (not the gsaadmin Entra ID user):

adminUsername:

    AzureAdmin

adminPassword:

    GSA-demo2024

![images](/images/local_admin_access.png)

Now log on to the client device as one of your regular users and attempt to connect via ssh again.

![images](/images/local_admin_access_denied.png)

### Internet Access
Entra [Internet Access](https://learn.microsoft.com/en-us/entra/global-secure-access/concept-internet-access) is an identity-centric Secure Web Gateway solution. It filters access to web content based on policies, and these can be applied to all users in an organization, groups or even individual user identities.

Internet Access is controlled by the Internet access profile under Traffic forwarding. 

When Enabled (1), the profile applies to all or selected Users and/or groups (2).  Internet access policies (3) then determine the which internet traffic from those users is sent to the Secure Web Gateway for evaluation, and which traffic is allowed to break out to internet directly from the user's machine.

Linked Conditional Access policies (4) then determine against which Security profiles (5), which in turn are made up of Web content filtering policies (6), the specific user's internet traffic is evaluated.

![image](/images/internet_access_hierarchy.png)

In the diagram below, the user's Security profile contains a Web content filtering policy blocking access to the Weapons category and allowing everything else. The Custom Bypass Internet access policy allows traffic to www.glock.com to break out directly from the client.

![image](/images/internet_flow.png)

Result is that the user can access Glock, even though this falls in the Weapons category, but cannot access Colt. Any other web destinations are tunneled to the Secure Web Gateway and are allowed to pass.

### Microsoft 
Entra [Microsoft Internet Access](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-manage-microsoft-profile) specifically acquires traffic to Microsoft services. This means that traffic for Microsoft 365 services is forwarded to the GSA gateway and is routed from there over the Microsoft network to the region hosting the user's tenant.

The Microsoft traffic profile controls the following policy groups: 

- Exchange Online
- SharePoint Online and Microsoft OneDrive.
- Microsoft 365 Common and Office Online (only Microsoft Entra ID and Microsoft Graph)

The GSA Micrsoft traffic profile makes it easier for companies to enhance their security posture through [Entra ID Tenant restrictions](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/tenant-restrictions). Tenant restrictions allow companies to control which Entra tenants can be accessed from their devices and networks, helping prevent data exfiltration from corporate devices to alien tenants. It works through including a list of permitted tenants in a header in authentication request to Entra ID. When Entra ID sees the `Restrict-Access-To-Tenants: <permitted tenant list>` in a request, it will only issue tokens for the permitted tenants listed.

In a traditional on-premise network, client internet access is through a forward proxy. The proxy would then  insert the `Restrict-Access-To-Tenants` header in authentication requests from client devices within the network.

With GSA [Universal tenant restrictions](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-universal-tenant-restrictions), the GSA gateway takes on the task of inserting headers in authentication requests both from devices running the GSA client and devices in Remote networks.

Tagging for Universal tenant restrictions (i.e. insertion of the `Restrict-Access-To-Tenants` header) is enabled under Global Secure Access - Settings - Session Management.

![image](/images/univ_tenant_restr_enable.png)

The Universal tenant restrictions policy, which controls the list of allowed tenants, is set under Identity - External Identities - Cross-tenant access settings. Click + Add organization to add alien tenants that users are allowed to access from devices and remote networks.

Click the link under Tenant restrictions (this initially reads Inherited from default), to configure whether all are only specific users and applications can access the alien tenant.

![image](/images/univ_tenant_restr_users.png)

:point_right: Users need to be specified with their object GUID here.

To test, log on to the alien tenant with a user from the alient tenant that has been given access, and one that has not. The user that does not have access to the alien tenant will see this message:

![image](/images/univ_tenant_restr_blocked.png)

## Remote networks
In addition to end-user devices with the GSA Client installed, GSA also supports remote networks. A remote network is a location, for example a branch office, with client devices that do not have the GSA Client installed but still need secure access to resources in the data center, on the internet and to Microsoft 365.

GSA Remote Networks lets a remote network connect to the service by means of an IPSec VPN tunnel between a router or firewall onpremise, and the GSA gateway. All traffic at the remote location is pointed to the local router, and this forwards traffic into the tunnel to the GSA gateway. GSA then controls access to private resources, internet and Micrsosft 365. It is obviously still possible to let some internet traffic break out locally. This is similar to the Custom Bypass policies in GSA Internet Access for clients, but is controlled locally through configuration on the router.

:point_right: at the time of writing in September 2024, Remote Networks only supports the Microsoft traffic profile, with Private and Internet access on the roadmap.

### Lab
A Remote Network is simulated through a separate VNET. The VNET contains a client VM running Windows 11, and a Cisco 8000v NVA. An IPSec tunnel connects the NVA to the GSA service's gateway. 

![image](/images/remote_network.png)

### Deployment

#### Accept terms of use of the Cisco 8000v image:

    az vm image terms accept -p cisco -f cisco-c8000v-byol --plan 17_13_01a-byol -o none

#### Deploy template:

    az deployment group create -g <rgname> --template-file remote.bicep --parameters location=<region>

When deployment completes, get the public IP address of the Cisco 8000v NVA `c8kpublicip` from the portal or through CLI:

    az network public-ip show -g <rgname> -n c8kpublicip --query ipAddress

#### Create a GSA Remote Network:

In the Entra portal in the Global Secure Access section, under Connect, click Remote networks, then click Create remote network at the top of the page.

![image](/images/create_remote_netw.png)

Give the new Remote network a name. Decide on a region, this is where the Gateway that this network will connect to is located.

![image](/images/create_remote_netw_basics.png)

Continue to the Connectivity tab at the top of the screen. 

Click Add a link, and enter configuration as shown:

![image](/images/create_remote_netw_addlink_general.png)

:point_right: Fill in the Details screen exactly as shown, as these parameters must match the IKEv2/IPSec configuration on the Cisco 8000v NVA.

![image](/images/create_remote_netw_addlink_details.png)

Enter pre-shared key `gsa123`. 

![image](/images/create_remote_netw_addlink_security.png)

After the remote network is created, click on View configuration under Connectivity details.

![image](/images/remote_network_configuration.png)

In the json that opens, look up and copy the "endpoint" address under "localConfigurations".

![image](/images/remote_network_endpoint.png)

#### Configure Cisco 8000v NVA

Copy the file [c8k.ios](https://github.com/mddazure/entra-gsa-lab/blob/main/c8k.ios) from this repository to a text editor.

Find and replace `entra-pubIPv4` by the endpoint address copied from the Entra Remote network configuration previously.

Log on to the Cisco 8000v NVA named c8k through Serial Console.

Username: 
    
    AzureAdmin

Password: 

    GSA-demo2024

Type `en` and then `conf t`.

Enter these commands:

    license boot level network-advantage addon dna-advantage
    do wr mem
    do reload

The NVA will now reboot. When rebooting is complete log on again through Serial Console.

Type `en` and then `conf t`.

Copy and paste in the modified contents of the c8k.ios file.

Type `end` and then `sh ip int brief`.

The interface Tunnel101 should show Up under both Status and Protocol.

![image](/images/c8k_sh_ip_int.png)

Type `copy run start` and confirm default prompts to store the configuration.

### Verification
The simulated remote network, remotevnet, contains a Windows 11 VM named clientvm. It is not Entra-joined and does not have the GSA client installed. 

A UDR attached to its subnet contains a default route forcing all outbound traffic to the c8k NVA.

Log on to clientvm through Bastion.

Username:

    AzureAdmin

Password: 

    GSA-demo2024

#### Microsoft Traffic

GSA Remote networks only supports the Microsoft Traffic profile at the time of this writing in October 2024. 

![image](/images/remote_netw_traffic_profile.png)

On clientvm, browse to www.office.com.

Log on with a user from an alien tenant who has been given permission to access the alient tenant in the Microsoft Traffic profile, as described [above](#microsoft). This user will be able to access all Microsoft 365 services under their tenant.

Log off and then log on with a user from the alien tenant that does not have permission to access the alient tenant.

This user will see this message:

![image](/images/univ_tenant_restr_blocked.png)

The GSA gateway advertises the [Microsoft 365 address ranges](https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide) via BGP to the NVA. 

Log on to c8k via Serial console, type `en` and `sh ip route`:

![image](/images/office_routes.png)

#### Internet access
Internet traffic from clientvm is routed to c8k, which has a default route pointing to the tunnel to the GSA gateway.

GSA Remote networks does not yet support the Internet Traffic profile. Outbound internet traffic sent to the GSA gateway from the NVA breaks out at the gateway unfiltered.

*Credits*

This article is based in part on [Azure Networking GBB Technical Readiness Session # 37](https://microsoft.sharepoint.com/:p:/t/AzureNetworkingTechnicalChamps/EeY_sG-n1ktAvw47MEoFxMcBFxwHGmQXEGtN1WtG5x7hXQ?e=INbbzh) on Global Secure Access (link accessible to Microsoft staff only), by [Adam Stuart](https://github.com/adstuart) and [Jose Moreno](https://blog.cloudtrooper.net/).



