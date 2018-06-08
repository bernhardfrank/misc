<#The Mission:

    Create a PowerShell Script that should deploy a single VM just like 
    https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/virtual-machines-windows/single-vm

    - create 2 Subnets within the VNET
    - Use variables 
    - Use Powershell help .... -examples 
    - Copy 'n Paste with pride!

     have fun!
#>

#region Variables
$RG = "SampleRG"
$Location = "NorthEurope"
$VNETName = "VNET"
$NSGName = "myNSG"
$AVSetName = "myAVSet"
$VMName = "myVMName"
$PublicIPAddressName = "myPIP"
$NICName = "myNICName"
$OSDiskCaching = "ReadWrite"
$DataDiskCaching = "ReadOnly"
$OSDiskName = "myOSDisk"
$DataDiskName = "myDataDisk"
$PremiumDiskTypes = @{"P4"=32 ; "P6"=64 ; "P10"=128 ; "P20"=512 ; "P30"=1024 ; "P40"=2048 ; "P50"=4095}    #https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits
$StandardDiskTypes = @{"S4"=32 ; "S6"=64 ; "S10"=128 ; "S20"=512 ; "S30"=1024 ; "S40"=2048 ; "S50"=4095}    #https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits
#endregion

#Login to Azure
Login-AzureRMAccount

#Create RG
New-AzureRmResourceGroup -Name $RG -Location $Location

#Create Subnet
$Subnets = @()
$Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet1" -AddressPrefix "192.168.1.0/24"
$Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet2" -AddressPrefix "192.168.2.0/24"

#Create VNET
$VNET = New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG -Location $Location -Subnet $Subnets -AddressPrefix "192.168.0.0/16"

#Create a Subnet after VNET was created
$Subnet3 = New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet3" -AddressPrefix "192.168.3.0/24"
$VNET = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG
$VNET.Subnets.Add($Subnet3)
Set-AzureRmVirtualNetwork -VirtualNetwork $VNET

#Create NSG
$NSGRules = @()
$NSGRules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Priority 101 -Description "inbound RDP access" -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange 3389 -DestinationAddressPrefix * -Access Allow -Direction Inbound 
$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $RG -Location $Location -SecurityRules $NSGRules

#Create PublicIP
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic

#Create NIC
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RG -Location $Location -SubnetId $VNET.Subnets.Item(0).id -PublicIpAddressId $PIP.Id 

#Create VM (Size,additional Data Disk (ReadCache of Data Disk), )

    #Create Availabilityset
    $AVSet = New-AzureRmAvailabilitySet -ResourceGroupName $RG -Name $AVSetName -Location $Location -PlatformUpdateDomainCount 1 -PlatformFaultDomainCount 1 -Sku Aligned
    
    #Get VMSize
    $VMSize = Get-AzureRmVMSize -Location $Location | Out-GridView -PassThru -Title "Select Your Size"
    $VM = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize.Name -AvailabilitySetId $AVSet.Id
    
    #Attach VNIC to VMConfig
    $VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NIC.Id

    #Get the image e.g. "MicrosoftSQLServer" Offer: "SQL2017-WS2016"
    $Publisher = (Get-AzureRmVMImagePublisher -Location $location | Out-GridView -PassThru).PublisherName 
    $PublisherOffer = Get-AzureRmVMImageOffer -Location $Location -PublisherName $Publisher | Out-GridView -PassThru
    
    $VMImageSKU = (Get-AzureRmVMImageSku -Location $Location -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer).Skus | Out-GridView -PassThru
    $VMImage = Get-AzureRmVMImage -Location $Location -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer -Skus $VMImageSKU | Sort-Object -Descending | Select-Object -First 1
    
    $VM= Set-AzureRmVMSourceImage -VM $VM -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer -Skus $VMImageSKU -Verbose -Version $VMImage.Version

    #Disable Boot Diagnostics for VM    (is demo - don't need it AND it would require storage account which I don't want to provision)
    $VM =  Set-AzureRmVMBootDiagnostics -VM $VM -Disable 

    #Create a Credential
    $Credential = Get-Credential -Message "Specify VM Login" #New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)
    $VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    
    #Config OSDisk
    $VM = Set-AzureRmVMOSDisk -VM $VM -Name $OSDiskName -Caching $OSDiskCaching -CreateOption FromImage -DiskSizeInGB 128

    #attach DataDisk
    $DataDiskConfig = New-AzureRmDiskConfig -SkuName Premium_LRS -DiskSizeGB $PremiumDiskTypes.P4 -Location $location -CreateOption Empty 
    $DataDisk = New-AzureRmDisk -ResourceGroupName $RG -DiskName $DataDiskName -Disk $DataDiskConfig 
    $VM = Add-AzureRmVMDataDisk -VM $vm -Name $DataDiskName -Caching $DataDiskCaching -ManagedDiskId $DataDisk.Id -Lun 1 -CreateOption Attach

    #new VM
    New-AzureRmVM -ResourceGroupName $RG -Location $location -VM $VM #-AsJob   #-AsJob immediately runs the job in the background -> get-job

   
#Custom Script Extension
    $myCSEURL = "https://raw.githubusercontent.com/bernhardfrank/misc/master/CustomScriptExtensions/DownloadISO.ps1"
    $URI = "http://ltspice.analog.com/software/LTspiceXVII.exe" 
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSEURL -Run "$(Split-Path -Leaf -Path $myCSEURL)" -Name DemoScriptExtension -Argument "$URI"
    

<#  cleanup
    Remove-AzureRmResourceGroup -Name $RG -Force -AsJob
#>