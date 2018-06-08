$azureLocationOfInterest = 'North Europe'
$VMsizesCSV = "C:\work\work\1_Daten & Wissensspeicher\1.4_Azure\VMsizesCSV.csv"
$MeterRegion = "EU North"
$VMRatesCSV = "C:\work\work\1_Daten & Wissensspeicher\1.4_Azure\VMRatesCSV.csv"

$StorageRatesCSV = "C:\work\work\1_Daten & Wissensspeicher\1.4_Azure\StorageRatesCSV.csv"
#export VM Typen als CSV
Get-AzureRmVMSize -Location $azureLocationOfInterest| Select-Object Name,NumberOfCores,MemoryInMB,MaxDataDiskCount,OSDiskSizeInMB,ResourceDiskSizeInMB | Export-Csv -Path $VMsizesCSV -NoTypeInformation -Delimiter ';'

#export VM types prices as csv
$NorthEurope =  Import-Csv -Path "C:\work\work\1_Daten & Wissensspeicher\1.4_Azure\RateCardAPI-NEuorpe.csv" -UseCulture
   
#Get prices for VMs Dv2
#$NorthEurope.Where({$_.MeterRegion -like $MeterRegion -and $_.MeterCategory -eq "Virtual Machines" -and  $_.MeterSubCategory -like "*_D2*_v2*"}) | ft Metersubcategory,@{Label="€/h";Expression={$convertable = "$_.MeterRates" -match '[0-9],[0-9]+'; if ($convertable) {$Matches[0]} else {$null}}},MeterName,MeterId,MeterRegion | Export-Csv -Path $VMRatesCSV -Delimiter ';' -NoTypeInformation
$NorthEurope.Where({$_.MeterRegion -like $MeterRegion -and $_.MeterCategory -eq "Virtual Machines"}) | Select-Object Metersubcategory,@{Label="Euros/h";Expression={$convertable = "$_.MeterRates" -match '[0-9]+,[0-9]+'; if ($convertable) {$Matches[0]} else {$null}}},MeterId,MeterName,MeterRegion | Export-Csv -Path $VMRatesCSV -UseCulture -NoTypeInformation 

$NorthEurope.Where({$_.MeterRegion -like "EU North" -and $_.MeterCategory -eq "Storage"}) | Select-Object MeterName,@{Label="Euros";Expression={$convertable = "$_.MeterRates" -match '[0-9]+,[0-9]+'; if ($convertable) {$Matches[0]} else {$null}}},Unit,MeterId,MeterSubCategory,MeterRegion | Export-Csv -Path $StorageRatesCSV -UseCulture -NoTypeInformation 
$NorthEurope | Export-Csv -Path "C:\work\work\1_Daten & Wissensspeicher\1.4_Azure\RateCardAPI-StorageNEuorpe.csv" -UseCulture -NoTypeInformation

