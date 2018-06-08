<#
    Register Azure Stack with Azure for Marketplace syndication

URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-register
Server: On MAS HOST

#>

<#region Download the RegisterWithAzure.ps1 script to temp folder
$urls = @("https://raw.githubusercontent.com/Azure/AzureStack-Tools/master/Registration/RegisterWithAzure.ps1")
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
#>


#region Register Azure Stack resource provider in Azure
    Add-AzureRmAccount -EnvironmentName "AzureCloud"
    Login-AzureRmAccount -EnvironmentName "AzureCloud"
    #if you have multiple subscriptions, run the following command to select the one you want to use
    Get-AzureRmSubscription -SubscriptionID 7870e81c-4b83-4b40-ac88-0bfe28fa6687 | Select-AzureRmSubscription
    Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack
#endregion


#region 
cd (dir C:\AzureStack-Tool* | Select-Object -First 1)

<#
Import-Module .\Connect\AzureStack.Connect.psm1

#Create the Azure Stack administrator's AzureRM environment 
Add-AzureRmEnvironment -Name AzureStackAdmin -ArmEndpoint "https://adminmanagement.local.azurestack.external" 

#Get the GUID value of the Active Directory(AD) user that is used to deploy the Azure Stack
#For Azure Active Directory use:
$AdminCreds = Get-Credential 
$AADTenantName = $AdminCreds.UserName -split '@' | select -Last 1     # e.g. "someAADomain.onmicrosoft.com"
#$TenantID = Get-DirectoryTenantID -AADTenantName $AADTenantName -EnvironmentName AzureStackAdmin
$TenantID = Get-AzsDirectoryTenantID -AADTenantName "$AADTenantName" -EnvironmentName AzureStackAdmin
#endregion 

cd C:\AzureStack-Tools\Registration
#.\RegisterWithAzure.ps1 -azureSubscriptionId "f55edc34-b2f6-42f6-b100-9f68e5110bb7" -azureDirectoryTenantName "AzureStackAAD.onmicrosoft.com" -azureAccountId "AzureStackAdmin@AzureStackAAD.onmicrosoft.com" -verbose
.\RegisterWithAzure.ps1 -azureSubscriptionId "f55edc34-b2f6-42f6-b100-9f68e5110bb7" -azureDirectoryTenantName "mySyndicationAAD.onmicrosoft.com" -azureAccountId "syndication@mySyndicationAAD.onmicrosoft.com" -verbose

#RegisterWithAzure.ps1 -azureDirectory AzureStackAAD.onmicrosoft.com -azureSubscriptionId f55edc34-b2f6-42f6-b100-9f68e5110bb7 -azureSubscriptionOwner AzureStackAdmin@AzureStackAAD.onmicrosoft.com
#>

#cd C:\AzureStack-Tools\Registration
Import-Module .\Registration\RegisterWithAzure.psm1

$AzureContext = Get-AzureRmContext
$CloudAdminCred = Get-Credential -UserName AZURESTACK\CloudAdmin -Message "Enter the cloud domain credentials to access the privileged endpoint"
#Add-AzsRegistration `
#    -CloudAdminCredential $CloudAdminCred `
#    -AzureSubscriptionId $AzureContext.Subscription.SubscriptionId `
#    -AzureDirectoryTenantName $AzureContext.Tenant.TenantId `
#    -PrivilegedEndpoint AzS-ERCS01 `
#    -BillingModel Development

Add-AzsRegistration -CloudAdminCredential $CloudAdminCred -AzureSubscriptionId $AzureContext.Subscription.SubscriptionId -AzureDirectoryTenantName $AzureContext.Tenant.Directory -PrivilegedEndpoint AzS-ERCS01 -Verbose    