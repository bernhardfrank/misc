<#

    For cleaning up an Azure AD from a previous Azure Stack installation

#>

Login-AzureRmAccount   #login to Azure subscription for the account you used to install Azure Stack

$apps = Get-AzureRmADApplication | where Displayname -Like "Azure*"
$apps|Set-AzureRmADApplication -AvailableToOtherTenants $false 
$apps | % {Remove-AzureRmADApplication -ObjectId $_.ObjectId -Force}