<#
 Configure guest directory

 see https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-enable-multitenancy#configure-guest-directory


#>


$tenantARMEndpoint = "https://management.local.azurestack.external"

## Replace the value below with the guest tenant directory. 

#$guestDirectoryTenantName = "hotmail.com" #"fabrikam.onmicrosoft.com"
$guestDirectoryTenantName =  "bernhardfhotmail.onmicrosoft.com"

#Login als bernhard_f@hotmail.com

Register-AzSWithMyDirectoryTenant `
 -TenantResourceManagerEndpoint $tenantARMEndpoint `
 -DirectoryTenantName $guestDirectoryTenantName `
 -Verbose

 <#
 now you can logon to Azure Stack with users from e.g. bernhard_frank@bernhardfhotmail.onmicrosoft.com
 bernhard_f@hotmail.com won't work
 
 use this url to logon to azure stack
 https://portal.local.azurestack.external/bernhardfhotmail.onmicrosoft.com 

 #>