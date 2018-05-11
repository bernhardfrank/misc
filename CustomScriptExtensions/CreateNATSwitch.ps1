<# 
    This Script Extension Creates a Hyper-V NAT Switch
#>

#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log -Append


$SwitchTest = Get-VMSwitch -Name "NATSwitch" -ErrorAction SilentlyContinue

if($SwitchTest -eq $null) {
    New-VMSwitch -Name "NATSwitch" -SwitchType Internal -Verbose
   
    $NIC = Get-NetAdapter  | where Name -like "vEthernet*(NatSwitch)"
   
    New-NetIPAddress -IPAddress 172.16.0.1 -PrefixLength 24 -InterfaceIndex $NIC.ifIndex -Verbose

    New-NetNat -Name "NATSwitch" -InternalIPInterfaceAddressPrefix "172.16.0.0/24" -Verbose
}


Stop-Transcript


