<#
  Run Right After Azure Stack PoC install
  
 Server: On MAS Host
 URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-run-powershell-script#activate-the-administrator-and-tenant-portals
#>


#Activate the administrator and tenant portals

& 'C:\Program Files\Internet Explorer\iexplore.exe'  'https://adminportal.local.azurestack.external/guest/signup'
& 'C:\Program Files\Internet Explorer\iexplore.exe'  'https://portal.local.azurestack.external/guest/signup'

#Reset the password expiration to 180 days
#Run the following command to display the current MaxPasswordAge of 42 days: 
Get-ADDefaultDomainPasswordPolicy
#Run the following command to update the MaxPasswordAge to 180 days:
Set-ADDefaultDomainPasswordPolicy -MaxPasswordAge 180.00:00:00 -Identity azurestack.local 
Get-ADDefaultDomainPasswordPolicy