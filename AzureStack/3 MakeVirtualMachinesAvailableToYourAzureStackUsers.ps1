<#
Make virtual machines available to your Azure Stack users

Server: On MAS Host
URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-add-default-image

URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-tutorial-tenant-vm

#>

#region Helper Functions
    function ShowOpenFileDialog ([string]$Title,[string]$InitialDirectory,[string]$FileFilter)
    {
    $myDialog = New-Object System.Windows.Forms.OpenFileDialog
    $myDialog.Title = "$Title"
    $myDialog.Multiselect = $true
    $myDialog.InitialDirectory = "$InitialDirectory"
    $myDialog.Filter = "$FileFilter"
    $result = $myDialog.ShowDialog()
    
    If($result -eq “OK”) 
    {
        #$myDialog.FileName
        $myDialog.FileNames
    }
    else 
    {
        $null
    }
}
#endregion

#Import the Azure Stack Connect and ComputeAdmin modules by using the following commands
cd (dir C:\AzureStack-Tool* | Select-Object -First 1)

Import-Module .\Connect\AzureStack.Connect.psm1
Import-Module .\ComputeAdmin\AzureStack.ComputeAdmin.psm1

#Create the Azure Stack administrator's AzureRM environment 
Add-AzureRMEnvironment -Name "AzureStackAdmin" -ArmEndpoint "https://adminmanagement.local.azurestack.external"

#Get the GUID value of the Active Directory(AD) user that is used to deploy the Azure Stack
#For Azure Active Directory use:
$Credential = Get-Credential 
$AADTenantName = $Credential.UserName -split '@' | select -Last 1     # e.g. "someAADomain.onmicrosoft.com"
$TenantID =  Get-AzsDirectoryTenantId -AADTenantName $AADTenantName -EnvironmentName AzureStackAdmin

Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantID -Credential $Credential

#Or for Active Directory Federation Services use 
#$TenantID = Get-DirectoryTenantID -ADFS -EnvironmentName AzureStackAdmin

#Add the Windows Server 2016 image to the Azure Stack marketplace 
$ISOPath = ShowOpenFileDialog "Where is your Server .iso?" "c:\" "Iso files(*.iso)|*.iso|All files (*.*)|*.*"

# Add a Windows Server 2016 Evaluation VM Image.
#New-Server2016VMImage -ISOPath $ISOPath -TenantId $TenantID -EnvironmentName "AzureStackAdmin" -Net35 $True -AzureStackCredentials $Credential

# Add a Windows Server 2016 Evaluation VM Image.
New-AzsServer2016VMImage -ISOPath $ISOPath -IncludeLatestCU -Net35 $true -Verbose -Location local

Get-AzsVMImage -Publisher MicrosoftWindowsServer -Offer WindowsServer -Version 1.0.0 -Sku 2016-Datacenter

#remove 
#Remove-AzsVMImage -Publisher MicrosoftWindowsServer -Offer WindowsServer -Version 1.0.0 -Sku 2016-Datacenter -verbose -KeepMarketplaceItem $false -whatif
#ggf. noch den addvmimagecontainer löschen falls ein provisioning vorher erfolgte
