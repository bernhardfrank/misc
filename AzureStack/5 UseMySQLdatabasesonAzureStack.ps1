<#
  Use MySQL databases as PaaS on Azure Stack
  
 Server: On MAS Host
 URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-mysql-resource-provider-deploy 
#>

#region download the MySQL connector to temp
    $urls = @("https://dev.mysql.com/get/Download/sConnector-Net/mysql-connector-net-6.9.9.msi")
    foreach ($url in $urls)
    {
               
        $fileName = split-path ($url) -Leaf

                    
        #download
        $filePath = "c:\temp\$fileName"
        if (Test-Path $filePath) {continue}
        invoke-webrequest $url -OutFile $filePath 
        Unblock-File $filePath
        #if ($filePath -like '*.zip')
        #{
        #    Expand-Archive -Path $filePath -DestinationPath $($filePath.Replace($fileName,'')+"\")
        #}
    }
   
#endregion

#region download the MySQL ServerRP installer executable file
    $url = "https://aka.ms/azurestackmysqlrp"
    [System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
    
    ## Add the method (GET, POST, etc.)
    $request.Method = 'HEAD'
    
    [System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()
    $fileName = split-path ($response.ResponseUri.AbsoluteUri) -Leaf
         
    #download
    invoke-webrequest $url -OutFile "c:\temp\$fileName"
    #silently expand selfextracting RAR file see: http://stackoverflow.com/questions/9194589/how-to-extract-a-self-extracting-exe-from-commandline
    Start-Process "C:\Temp\$filename" -ArgumentList "-d""c:\temp\MySqlServerRP"" -s"
#endregion

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

# Change directory to the folder where you extracted the installation files
cd "c:\temp\MySQLServerRP"
#.\DeployMySQLProvider.ps1 -DirectoryTenantID $tenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "MySqlRG" -VmName "MySQLRP" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -AcceptLicense
#.\DeployMySQLProvider.ps1 -DirectoryTenantID $TenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "MySqlRG" -VmName "MySQLRP" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -AcceptLicense -DependencyFilesLocalPath "c:\temp\"
.\DeployMySQLProvider.ps1 -DirectoryTenantID $tenantID -AzCredential $AdminCreds -VMLocalCredential $vmLocalAdminCreds -ResourceGroupName "MySqlRG" -VmName "MySQLRP" -ArmEndpoint "https://adminmanagement.local.azurestack.external" -TenantArmEndpoint "https://management.local.azurestack.external" -DefaultSSLCertificatePassword $PfxPass -AcceptLicense -DependencyFilesLocalPath "c:\temp\"



#manually download MySQL from https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.19-winx64.zip 
# or https://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-5.7.19.0.msi

#wait for VM "MySQLRP" to be created then login and:
#download & install requirements Visual C++ Redistributable Packages for Visual Studio 2013 (both x86 and x64)
#then install mysql into MySQLRP
# configure MYsql instance to 
