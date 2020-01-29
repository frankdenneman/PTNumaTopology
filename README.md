# Abstract

http://www.frankdenneman.nl will feature an extensive write-up soon.

# The Script Set
The purpose of this script module is to identify the PCIe Device to NUMA Node locality within a VMware ESXi Host and set the vCPU NUMA affinity accordingly to isolate the vCPU and Memory of the VM in the same domain as the GPU device. This module presents the NUMA topology of a PCI Device that is assigned as a PassThrough (PT) device to a virtual machine on the VMware vSphere platform, The Get function retrieves information of registered VMs, PCI-ID of passthrough devices configured, PCI device NUMA node, NUMA Node Affinity VM advanced setting and Powerstate of VM. The Set function provides the ability to set a NUMA Node affinity advanced setting of powered-off VMs

Please note that `Get-PTNumaTopology` function only collect information and do not alter any configuration in any way possible. The `Set-PTNumaTopology` function writes the advanced configuration setting `"numa.affinity"` and a value to the VMX file of a powered-off VM.

## Requirements
* VMware PowerCLI
* Connection to VMware vCenter
* Unrestricted Script Execution Policy
* Posh-SSH
* Root Access to ESXi hosts
* Please note that Posh-SSH only works on Windows version of PowerShell.

The VMware PowerCLI script primarily interfaces with the virtual infrastructure via a connection to the VMware vCenter Server. A connection (Connect-VIServer) with the proper level of certificates must be in place before executing these scripts. The script does not initiate any connect session itself. It assumes this is already in-place.

As the script extracts information from the VMkernel Sys Info Shell (VSI Shell) the script uses Posh-SSH to log into ESXi host of choice and extracts the data from the VSI Shell for further processing. The Posh-SSH module needs to be installed before running the PCIe-NUMA-Locality scripts, the script does not install Posh-SSH itself. This module can be installed by running the following command Install-Module -Name Posh-SSH (Admin rights required). More information can be found at https://github.com/darkoperator/Posh-SSH

Root access is required to execute a vanish command via the SSH session. It might be possible to use SUDO, but this has functionality has not been included in the script (yet). The script uses Posh-SSH keyboard-interactive authentication method and presents a screen that allows you to enter your root credentials securely.

## Script Content
Each script consists of three stages, Host selection & logon, data collection, and data modeling. The script uses the module [Posh-SSH](http://www.lucd.info/knowledge-base/use-posh-ssh-instead-of-putty/) to create an SSH connection and runs a vsish command directly on the node itself. Due to this behavior, the script creates an output per server and cannot invoke at the cluster level. 

### Host Selection & Logon
The script requires you to enter the FQDN of the ESXi Host, the script initiates the SSH session to the host, requiring you to login with the root user account of the host. 

# Using the Script Set
- Step 1. Download the PTNumaTopology Powershell Module `PTNumaTopology.psm1` by clicking the "Download" button on this page.
- Step 2. Open PowerCLI session.
- Step 3. [Connect to VIServer ](https://blogs.vmware.com/PowerCLI/2013/03/back-to-basics-connecting-to-vcenter-or-a-vsphere-host.html)
- Step 4. Import this module into your environment

<img src="images/00-Import-Module-Command.png">

- Step 5. (Optional) verify if the module has loaded

<img src="images/01-Get-Module-Command.png">

- Step 6. Execute Get-PTNumaTopology command and specify the FQDN of the ESXi host. For example: `Get-PTNumaTopology -esxhost sc2esx27.vslab.local`. As the script needs to execute a command on the ESXi host localy an SSH session is initiated. This results in a prompt for a (root) username and password in a separate login screen.

<img src="images/02-Get-PTNumaTopology-Command.png">  

- Step 7. Verify the output of the `Get-PTNumaTopology` command

<img src="images/03-Get-PTNumaTopology-Result.png">  

The output shows the VM first that are not configured with a passthrough device. The script proceeds in displaying the registered virtual machines that do have a passthrough device configured. The output shows the VM Name, the PCIe address of the passthrough device (identical to the UI), the NUMA node the PCI device is connected to, the presence of the VM NUMA Node affinity advanced setting in the VMX and its value and the last column shows the powerstate of the VM.

The script closes the SSH connection while exiting to the commmand-line. If necessary you can set an advanced setting on the  VM specificyin the NUMA affinity of the vCPUs by using the `Set-PTNumaTopology` command.

-Step 1. Execute Set-PTNumaTopology command and specify the FQDN of the ESXi host. For example: `Set-PTNumaTopology -esxhost sc2esx27.vslab.local`.

<img src="images/04-Set-PTNumaTopology-Command.png"> 

- Step 2. As a failsafe the script proceeds to ask if you would liek to set the NUMA node affinity of a powered off VM.
- Step 3. Provide the name of the powered-off VM.
- Step 4. The next step is to provide the NUMA Node you want the vCPUs to set the affinity for. Use the same number listed in the PCI NUMA Node column behind the attached passthrough device.

Setting an advanced setting means that the system is writing to this to the VMX file and the VMX file is in a locked state during the power-on state of a VM.



<img src="images/05-Set-PTNumaTopology-Result.png"> 
<img src="images/06-Verify-SetPTNumaTopology-Command.png">  

