# Windows 11 nested VM setup

Download the "Windows 11 (business editions), version 23H2" .iso disk image from https://my.visualstudio.com/downloads. This requires a Visual Studio subscription. 

(If you do not have a Visual Studio subscription, you may download a Windows 11 disk image from https://www.microsoft.com/en-us/software-download/windows11).

Open Hyper-V Manager (type Hyper-V in the Search box).

Click Quick Create under Actions.
In the window that appears, click Local installation source and then Change installation source.

![image](/images/hyper-v/quick_create.png)

  Select the .iso disk image downloaded earlier and click Create Virtual Machine.

![image](/images/hyper-v/vm_created.png)

Click Connect and then Start. Simultaneously repeatedly press Enter on your keyboard.
  
:point_right: If the VM does not boot from iso, in the Virtual Machine Connection window click Action and select Reset from the drop down.
Then click Reset in the pop-up, and simultaneously repeatedly press Enter on your keyboard.

![image](/images/hyper-v/reset_vm.png)


This should let the VM boot from the disk image.
  
The Windows 11 installation process will start, select Windows 11 Enterprise as the version to install.

Follow along and respond to the dialogs as you need.

When the installation is complete, log in with a user id from your Entra tenant: {username}@{tenantname}.onmicrosoft.com.

If the Entra user is configured to join devices to Entra, the VM wil automatically be joined on first login.

![image](/images/hyper-v/user_may_join_device.png)

:point_right: Ensure all Entra users you will be testing with are local administrators on the Entra-joined test devices. This is not a requirement for Entra GSA to work, but it makes accessing Advanced diagnostincs and Logs in the GSA Client easier.

In the Entra portal, navigate to Devices - All devices - Device settings and click "Manage Additional local administrators on all Microsoft Entra joined devices".

On the next page, click + Add assignments, select all users and click Assign.

![image](/images/hyper-v/add_local_admins.png)




