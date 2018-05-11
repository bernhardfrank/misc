<# 
    This Script Extension installs Hyper-v 

#>

#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log

Install-WindowsFeature Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose

Stop-Transcript