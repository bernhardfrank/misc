<# 
    This Script Extension downloads a Windows Server Eval Iso

#>

Param
  (
   [Parameter(Mandatory=$True,Position=1)] 
   [string] $URI
  ) 


#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log -Append

$URIPath = $tmpDir + "\$(Split-Path $URI -Leaf)"


if (!(Test-Path $URIPath )) 
{
    Write-Output "starting download...."
    start-bitstransfer "$URI" "$URIPath" -Priority High -RetryInterval 60 -Verbose -TransferType Download
    Write-Output "finished downloading: $URIPath"
}

Stop-Transcript


