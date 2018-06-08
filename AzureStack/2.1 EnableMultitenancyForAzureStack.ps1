<#
enable Multitenancy in Azure Stack.

 see https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-enable-multitenancy

 run first:
 1) "C:\Temp\bfrank\1 InstallPowerShellforAzureStack.ps1"
 2) "C:\Temp\bfrank\2 DownloadAzureStacktoolsfromGitHub.ps1"

 Run on MAS Host
#>


cd \
cd AzureStack-Tools-master
Import-Module .\Connect\AzureStack.Connect.psm1
Import-Module .\Identity\AzureStack.Identity.psm1

$adminARMEndpoint = "https://adminmanagement.local.azurestack.external"

## Replace the value below with the Azure Stack directory
$azureStackDirectoryTenant = "bfrankdemo.onmicrosoft.com" #"contoso.onmicrosoft.com"

## Replace the value below with the guest tenant directory. 
$guestDirectoryTenantToBeOnboarded = "bernhardfhotmail.onmicrosoft.com" #"fabrikam.onmicrosoft.com"

## Replace the value below with the name of the resource group in which the directory tenant registration resource should be created (resource group must already exist).
$ResourceGroupName = "system.local"


#Login to Azure Stack when asked
Register-AzSGuestDirectoryTenant -AdminResourceManagerEndpoint $adminARMEndpoint `
 -DirectoryTenantName $azureStackDirectoryTenant `
 -GuestDirectoryTenantName $guestDirectoryTenantToBeOnboarded `
 -Location "local" `
 -ResourceGroupName $ResourceGroupName

 <#
 Unregister-AzSGuestDirectoryTenant -AdminResourceManagerEndpoint $adminARMEndpoint `
 -DirectoryTenantName $azureStackDirectoryTenant `
 -GuestDirectoryTenantName $guestDirectoryTenantToBeOnboarded `
  -ResourceGroupName $ResourceGroupName

  #>
 
