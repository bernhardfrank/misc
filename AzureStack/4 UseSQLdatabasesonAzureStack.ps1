<#
  Use SQL databases on Azure Stack
  
 Server: On MAS Host
 URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-sql-resource-provider-deploy 
#>

#region download the SQL Server RP installer executable file
    #$url = "https://aka.ms/azurestacksqlrptp3"
    $url = "https://aka.ms/azurestacksqlrp"
    [System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
    
    ## Add the method (GET, POST, etc.)
    $request.Method = 'HEAD'
    
    [System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()
    $fileName = split-path ($response.ResponseUri.AbsoluteUri) -Leaf
         
    #download
    invoke-webrequest $url -OutFile "c:\temp\$fileName"
    #silently expand selfextracting RAR file see: http://stackoverflow.com/questions/9194589/how-to-extract-a-self-extracting-exe-from-commandline
    Start-Process "C:\Temp\$filename" -ArgumentList "-d""c:\temp\SQLServerRP"" -s"
#endregion

#Import the Azure Stack Connect and ComputeAdmin modules by using the following commands
cd (dir C:\AzureStack-Tool* | Select-Object -First 1)

Import-Module .\Connect\AzureStack.Connect.psm1

#Create the Azure Stack administrator's AzureRM environment 
Add-AzureRmEnvironment -Name AzureStackAdmin -ArmEndpoint "https://adminmanagement.local.azurestack.external" 

#Get the GUID value of the Active Directory(AD) user that is used to deploy the Azure Stack
#For Azure Active Directory use:
$AdminCreds = Get-Credential 
$AADTenantName = $AdminCreds.UserName -split '@' | select -Last 1     # e.g. "someAADomain.onmicrosoft.com"
#$TenantID = Get-DirectoryTenantID -AADTenantName $AADTenantName -EnvironmentName AzureStackAdmin
$TenantID = Get-AzsDirectoryTenantID -AADTenantName "$AADTenantName" -EnvironmentName AzureStackAdmin


#Or for Active Directory Federation Services use 
#$TenantID = Get-DirectoryTenantID -ADFS -EnvironmentName AzureStackAdmin

$vmLocalAdminPass = ConvertTo-SecureString ($AdminCreds.GetNetworkCredential().Password) -AsPlainText -Force
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass)

# Change directory to the folder where you extracted the installation files
cd "c:\temp\SQLServerRP"

# change this as appropriate
$PfxPass = ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force

#Deploy the SQL Provider and,...
# a) let the script download the SQL SErver 2014 SP1 for you (0,5h)
.\DeploySQLProvider.ps1 -DirectoryTenantID $tenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "SqlRPRG" -VmName "SqlVM" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -DefaultSSLCertificatePassword $PfxPass -DependencyFilesLocalPath "C:\Temp\SQLServerRP\SQLServer2016SP1-FullSlipstream-x64-ENU.iso"

#uninstall
.\DeploySQLProvider.ps1 -DirectoryTenantID $tenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "SqlRPRG" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -Uninstall -Verbose
# b) or do it manually and provide the path  ("http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso")
#.\DeploySQLProvider.ps1 -DirectoryTenantID $tenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "SqlRPRG" -VmName "SqlRPVM" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -DependencyFilesLocalPath %Path to SQLServer2014SP1-FullSlipstream-x64-ENU.iso%
