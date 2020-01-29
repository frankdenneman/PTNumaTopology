#Author: Frank Denneman
#Version: '1.0.0'
#Date: 01-29-2020
#Requires -Modules posh-ssh
#https://github.com/darkoperator/Posh-SSH
#Install-Module -Name Posh-SSH

Function Get-PTNumaTopology 
{
    [cmdletbinding()]
        Param(
            [parameter(Mandatory)]
            [string]$esxhost
        )
    Process {

        #Close all SSH Sessions
        $OpenSessions = Get-SSHSession
        Foreach ($sid in $OpenSessions.SessionId) {Remove-SSHSession -Index "$_"
        echo "Closing SSH session"}

        #Connect to Host via SSH - This will trigger a login screen
        $session = New-SSHSession -ComputerName $esxhost -Credential $cred –AcceptKey

        $AdvancedSetting = "numa.nodeAffinity"
        $PTVMs= Get-VM -Location $esxhost

        $PTVMsOutput = @()
        foreach ($PTVM in $PTVMs) {
            Try{  

                Filter PTVM0 { $_ }
                Filter PTVM1 { $_.ExtensionData.Config.Hardware.Device.Backing.Id }
                Filter PTVM3 { ($_ | Get-AdvancedSetting -Name $AdvancedSetting).Value }
                Filter PTVM4 { $_.PowerState}

                Filter PTDV0 { $_ }
                Filter PTDV1 { $_[5,6] -join '' }
                Filter PTDV2 { “0x” +$_ }
                Filter PTDV3 { [int]$_ }
                Filter PTDV4 { "vsish -e get /hardware/pci/seg/0/bus/$_/slot/0/func/0/pciConfigHeader | grep 'Numa node'"}
                Filter PTDV5 { Invoke-SSHCommand -SSHSession $session -Command $PTDV4 }
                Filter PTDV6 { $_ | Out-String -Stream | Select-String -Pattern "Numa node"}
                Filter PTDV7 { $_.ToString().Trim("Output     : {Numa node:   }") }

                $tempObj = New-Object -TypeName PSObject

                #Collect VM info

                $PTVM0 = $PTVM | PTVM0
                $tempObj | Add-Member -MemberType NoteProperty -Name "VM Name" -Value $PTVM0

                $PTVM1 = $PTVM | PTVM1
                $tempObj | Add-Member -MemberType NoteProperty -Name "PCI-ID" -Value $PTVM1
    
                $PTVM3 = $PTVM | PTVM3
                $tempObj | Add-Member -MemberType NoteProperty -Name "VM NUMA Node Affinity" -Value $PTVM3 

                $PTVM4 = $PTVM | PTVM4
                $tempObj | Add-Member -MemberType NoteProperty -Name "PowerState" -Value $PTVM4

                #Enumerate NUMA Locality PCI Device connected to VM as passthrough
  
                $PTDV1 = $PTVM1 | PTDV1
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV1" -Value $PTDV1
    
                $PTDV2 = $PTDV1 | PTDV2
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV2" -Value $PTDV2
    
                $PTDV3 = $PTDV2 | PTDV3
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV3" -Value $PTDV3

                $PTDV4 = $PTDV3 | PTDV4
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV4" -Value $PTDV4
    
                $PTDV5 = $PTDV4 | PTDV5
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV5" -Value $PTDV5
    
                $PTDV6 = $PTDV5 | PTDV6
                $tempObj | Add-Member -MemberType NoteProperty -Name "PTDV6" -Value $PTDV6
    
                $PTDV7 = $PTDV6 | PTDV7
                $tempObj | Add-Member -MemberType NoteProperty -Name "PCI NUMA Node" -Value $PTDV7

                $PTVMsOutput += $tempObj
            }

            Catch{
                Write-Host -ForegroundColor White -NoNewline "VM:";
                Write-Host -ForegroundColor Green -NoNewline " $PTVM0"; 
                Write-Host -ForegroundColor White -NoNewline; " - No Passthrough Device Configured"
            }
        }

        #Provide Output

        $PTVMsOutput | select-object "VM Name", "PCI-ID", "PCI NUMA Node", "VM NUMA Node Affinity", "PowerState" | Format-Table -Autosize 

        $OpenSessions = Get-SSHSession
        Foreach ($sid in $OpenSessions.SessionId) {Remove-SSHSession -Index "$_"
        echo "Closing SSH session"} 
}
}

Function Set-PTNumaTopology 
{
    [cmdletbinding()]
        Param(
            [parameter(Mandatory)]
            [string]$esxhost
        )
    Process {

        $UserInput = Read-Host "Would you like to set the NUMA node affinity for a VM? (Y/N)"
            if($UserInput -eq "Y"){
                $vmname = Read-Host "Enter Name PoweredOff VM"
                $NumaNode = Read-Host "Enter NUMA Node"
                New-AdvancedSetting -Entity "$vmname" -Name numa.nodeAffinity -Value "$NumaNode" -Force -Confirm:$false
               }

            else {
               write-host("Ending Script")
            }

   }        
}
 
