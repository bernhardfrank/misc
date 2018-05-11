<#

    This script creates a demo Hyper-V host in an Azure Virtual Machine of
    
    it uses Custom Script Extensions to automate as much as possible install hyper-v, creates a NAT Switch, formats data disks, downloads an Iso, creates a dummy VM

#>

#region Variables
$RG = "NestedHyper-V"
$Location = "NorthEurope"
$VNETName = "VNET"
$NSGName = "NSG-HyperV"
$AVSetName = "AVSet-HyperV"
$VMName = "HyperV-01"
$PublicIPAddressName = "PIP-HyperV-01"
$NICName = "MGMTNic-HyperV-01"
$PrivateIpAddress ="10.0.1.6"
$OSDiskCaching = "ReadWrite"
$DataDiskCaching = "ReadOnly"
$VMLocalAdminUser = "bfrank"
$OSDiskName = "OSDisk-HyperV-01"
$DataDiskName = "DataDisk-HyperV-01"
$PremiumDiskTypes = @{"P4"=32 ; "P6"=64 ; "P10"=128 ; "P20"=512 ; "P30"=1024 ; "P40"=2048 ; "P50"=4095}    #https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits
$StandardDiskTypes = @{"S4"=32 ; "S6"=64 ; "S10"=128 ; "S20"=512 ; "S30"=1024 ; "S40"=2048 ; "S50"=4095}    #https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits
#endregion

#Login to Azure
Login-AzureRMAccount

#Create RG
New-AzureRmResourceGroup -Name $RG -Location $Location

#Create Subnet
$Subnets = @()
$Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "MGMT" -AddressPrefix "10.0.1.0/24"

#Create VNET
$VNET = New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG -Location $Location -Subnet $Subnets -AddressPrefix "10.0.1.0/24"


#Create NSG
$NSGRules = @()
$NSGRules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Priority 101 -Description "inbound RDP access" -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange 3389 -DestinationAddressPrefix * -Access Allow -Direction Inbound 
$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $RG -Location $Location -SecurityRules $NSGRules

#Create PublicIP
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic

#Create NIC
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RG -Location $Location -SubnetId $VNET.Subnets.Item(0).id -PublicIpAddressId $PIP.Id -PrivateIpAddress $PrivateIpAddress

#Create VM (Size,additional Data Disk (ReadCache of Data Disk), )

    #Create Availabilityset
    $AVSet = New-AzureRmAvailabilitySet -ResourceGroupName $RG -Name $AVSetName -Location $Location -PlatformUpdateDomainCount 1 -PlatformFaultDomainCount 1 -Sku Aligned
    
    #Get VMSize
    $VMSize = Get-AzureRmVMSize -Location $Location | where name -Match "[a-zA-Z]_D[s0-9]+_v3|[a-zA-Z]_E[s0-9]+_v3" | Out-GridView -PassThru -Title "Select Your Hyper-V capable VM-size"
    $VM = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize.Name -AvailabilitySetId $AVSet.Id
    
    #Attach VNIC to VMConfig
    $VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NIC.Id

    #Get the image e.g. 
    $VMImage = Get-AzureRmVMImage -Location $Location -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" | Sort-Object -Descending | Select-Object -First 1
    $VM= Set-AzureRmVMSourceImage -VM $VM -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Verbose -Version $VMImage.Version

    #Disable Boot Diagnostics for VM    (is demo - don't need it AND it would require storage account which I don't want to provision)
    $VM =  Set-AzureRmVMBootDiagnostics -VM $VM -Disable 

    #Create a Credential
    $Credential = Get-Credential -Message "Create Credential for your Azure VM"
    $VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    
    #Config OSDisk
    $VM = Set-AzureRmVMOSDisk -VM $VM -Name $OSDiskName -Caching $OSDiskCaching -CreateOption FromImage -DiskSizeInGB 128

    #attach DataDisk
    $DataDiskConfig = New-AzureRmDiskConfig -SkuName Premium_LRS -DiskSizeGB $PremiumDiskTypes.P10 -Location $location -CreateOption Empty 
    $DataDisk = New-AzureRmDisk -ResourceGroupName $RG -DiskName $DataDiskName -Disk $DataDiskConfig 
    $VM = Add-AzureRmVMDataDisk -VM $vm -Name $DataDiskName -Caching $DataDiskCaching -ManagedDiskId $DataDisk.Id -Lun 1 -CreateOption Attach

    #new VM
    New-AzureRmVM -ResourceGroupName $RG -Location $location -VM $VM -AsJob   #-AsJob immediately runs the job in the background -> get-job


#region Custom Script Extensions 
    #Custom Script Extension to install Hyper-V
    $myCSE1URL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/InstallHyperV.ps1"
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE1URL -Run "$(Split-Path -Leaf -Path $myCSE1URL)" -Name DemoScriptExtension
    
    #restart to finalize Hyper-V installation
    Restart-AzureRmVM -ResourceGroupName $RG -Name $VMName
    
    #remove 1st CSE...
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name DemoScriptExtension -Force
    
    #CSE for creating a NAT Switch in Hyper-V
    $myCSE2URL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/CreateNATSwitch.ps1"
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE2URL -Run "$(Split-Path -Leaf -Path $myCSE2URL)" -Name DemoScriptExtension
    
    #remove 2nd CSE...
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name DemoScriptExtension -Force
    
    #CSE for downloading a Windows Server ISO file - input the URI...
    $myCSE3URL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/DownloadISO.ps1"
    $URI = "http://download.microsoft.com/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO" 
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE3URL -Run "$(Split-Path -Leaf -Path $myCSE3URL)" -Name DemoScriptExtension -Argument "$URI"
    
    #remove 3rd CSE...
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name DemoScriptExtension -Force
    
    #CSE for finding and formatting data disks...
    $myCSE4URL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/FindnFormatDataDisks.ps1"
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE4URL -Run "$(Split-Path -Leaf -Path $myCSE4URL)" -Name DemoScriptExtension -Argument "$URI"
    
    #remove 4th CSE...
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name DemoScriptExtension -Force
    
    #CSE for createing a dummy vm...
    $myCSE5URL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/CreateVM.ps1"
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE5URL -Run "$(Split-Path -Leaf -Path $myCSE5URL)" -Name DemoScriptExtension -Argument "$URI"
    
    #cleanup CSEs
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name DemoScriptExtension -Force

#endregion

<#cleanup
    Remove-AzureRmResourceGroup -Name $RG -Force -AsJob
#>