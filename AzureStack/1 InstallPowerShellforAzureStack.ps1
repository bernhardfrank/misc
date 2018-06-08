<#
Install PowerShell for Azure Stack 

Server: On MAS Host
URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-powershell-install

#>

#bfrank: trust the PSGallery to eliminate prompts
set-psrepository -Name PSGallery -installationpolicy trusted
Get-PSRepository #should now be listed as trusted

#uninstall old ones
Get-Module -ListAvailable | where-Object {$_.Name -like "Azure*"} | Uninstall-Module

# Install the AzureRM.Bootstrapper module
Install-Module -Name AzureRM.BootStrapper -Force

# Installs and imports the API Version Profile required by Azure Stack into the current PowerShell session.
Use-AzureRmProfile -Profile 2017-03-09-profile -Force -Confirm:$false

Install-Module -Name AzureStack -RequiredVersion 1.2.11 -Confirm:$false

#confirm installation
Get-Module -ListAvailable | where-Object {$_.Name -like "Azure*"}