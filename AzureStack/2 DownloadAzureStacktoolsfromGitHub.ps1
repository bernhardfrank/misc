<#
Download Azure Stack tools from GitHub
AzureStack-Tools is a GitHub repository that hosts PowerShell modules 
that you can use to manage and deploy resources to Azure Stack. 
You can download and use these PowerShell modules from MAS-CON01, 
Azure Stack host computer, or from a windows-based external client through VPN connectivity. 
To obtain these tools, clone the GitHub repository or download the AzureStack-Tools folder. 

Server: On MAS HOST
URL: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-powershell-download

#>

#TODo: user choice

<#region Option #1: Using GIT
    #download GIT
    $url = 'https://github.com/git-for-windows/git/releases/download/v2.13.3.windows.1/Git-2.13.3-64-bit.exe'
    $path = "c:\temp\$(split-path $url -leaf)"
    invoke-webrequest $url -OutFile $path
    
    #silently install GIT
    start-process $path -ArgumentList "/silent /log=""c:\temp\gitinstall.log"""

    # Change directory to the root directory 
    cd \
    
    # clone the repository
    Start-Process -FilePath "C:\Program Files\Git\bin\git.exe" -argumentlist "clone https://github.com/Azure/AzureStack-Tools.git --recursive"
    
    # Change to the tools directory
    cd AzureStack-Tools
#endregion
#> 

#region Option #2: Download Tools Folder
    # Change directory to the root directory 
    cd \
    
    # Download the tools archive
    invoke-webrequest https://github.com/Azure/AzureStack-Tools/archive/master.zip -OutFile master.zip
    
    # Expand the downloaded files
    expand-archive master.zip -DestinationPath . -Force
    
    # Change to the tools directory
    cd AzureStack-Tools-master
#endregion