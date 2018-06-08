<#
    Creates a VM with name "TenantSystem" on MAS host to be used to 

URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-app-service-deploy#download-the-required-components
Server: On MAS HOST

#>

$VHDPath = "Y:\WS2016Eval.vhdx"

$VM=New-VM -Path C:\VMs -Name TenantSystem -MemoryStartupBytes 4096MB -Generation 2 -SwitchName Public* -NoVHD
Set-VM -VM $vm -ProcessorCount 4 -AutomaticStopAction ShutDown
mkdir "C:\VMs\TenantSystem\Virtual Hard Disks\"
Copy-Item $VHDPath -Destination "C:\VMs\TenantSystem\Virtual Hard Disks\"
Add-VMHardDiskDrive -VM $vm -ControllerType SCSI -ControllerLocation 0 -ControllerNumber 0 -Path "C:\VMs\TenantSystem\Virtual Hard Disks\WS2016Eval.vhdx"

$bootorder = (Get-VMFirmware -VM $vm).BootOrder
Set-VMFirmware -VM $vm -FirstBootDevice ($bootorder | where {$_.BootType -eq "Drive" -and ($_.Device -like "*location 0*")})
