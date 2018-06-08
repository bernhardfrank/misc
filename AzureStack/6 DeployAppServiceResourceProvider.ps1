<#
    Add an App Service resource provider to Azure Stack

URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-app-service-deploy#download-the-required-components
Server: On MAS HOST

#>

#region Donwload the Download the App Service on Azure Stack preview installer and Download the App Service on Azure Stack deployment helper scripts.
$urls = @("http://aka.ms/appsvconmasrc1installer", "http://aka.ms/appsvconmasrc1helper")
foreach ($url in $urls)
{
    [System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
    
    ## Add the method (GET, POST, etc.)
    $request.Method = 'HEAD'
    
    [System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()
    $fileName = split-path ($response.ResponseUri.AbsoluteUri) -Leaf

    #download
    $filePath = "c:\temp\$fileName"
    if (Test-Path $filePath) {continue}
    invoke-webrequest $url -OutFile $filePath 
    Unblock-File $filePath
    if ($filePath -like '*.zip')
    {
        Expand-Archive -Path $filePath -DestinationPath $($filePath.Replace('.zip','')+"\")
    }
}
#endregion

#make sure you are azurestack\AzureStackAdmin -> execute the Create-AppServiceCerts.ps1 
if ($env:USERNAME -ne "AzureStackAdmin") {exit}
cd "C:\Temp\AppServiceHelperScripts\"
$pfxPassword = ConvertTo-SecureString "Bu1ldmycl0ud!" -AsPlainText -Force
#The script creates three certificates, in the same folder as the create certificates script, that are needed by App Service.
.\Create-AppServiceCerts.ps1 -pfxPassword $pfxPassword -DomainName "local.azurestack.external" -CertificateAuthority "AzS-CA01.azurestack.local"

Start-Process c:\temp\AppService.exe -argumentlist "/log C:\temp\AppService.exe.log "

#'sa'
#'SQLRPVM.local.cloudapp.azurestack.external'
