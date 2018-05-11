<# 
    This Script Extension tries to create a dummy VM.... 

#>

#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log -Append

$VmName = "W2kEval"
#we put VMs on Disk with most free space
$VMPath = "$((Get-Volume | Sort-Object sizeRemaining -Descending | Select-Object -First 1).Driveletter)" + ":\VMs"
$VmDirectory = "$VMPath\$VMName"
$VHDDirectory = $VmDirectory+'\Virtual Hard Disks'
New-Item -Path $VHDDirectory -ItemType Directory
New-VM -Name $VmName -MemoryStartupBytes 1GB -NewVHDPath $($VHDDirectory+"\"+$VmName+".vhdx") -NewVHDSizeBytes 40GB -Path $VMPath -Generation 2 -SwitchName "NATSwitch" | Set-VM -ProcessorCount 1 -AutomaticStopAction ShutDown -AutomaticStartAction Nothing

#locate iso and attach as DVD
$IsoPath = Get-Item "$tmpDir\*server*.iso" | Select-Object -First 1
Add-VMDvdDrive -VMName $VmName -Path $($IsoPath.FullName)

#make DVD bootable
Set-VMFirmware -VMName $VmName -FirstBootDevice $(Get-VMDvdDrive -VMName $VmName)

Stop-Transcript