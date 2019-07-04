# PS script to tagging jpg files with MS Azure cognitive services

# Finding the following PS modules in https://www.powershellgallery.com

# PSCognitiveService --> https://github.com/PrateekKumarSingh/PSCognitiveService
# AzureRM            --> https://github.com/Azure/azure-powershell


$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import parameter from PixsConf.xml 
$confFile = $myDir + '\PixsConf.xml'
[xml]$configFile = Get-Content $confFile

$logLevel = $configFile.Settings.Log.Level
$logFile = $configFile.Settings.Log.LogPath + $configFile.Settings.Log.LogName + '_%{+%Y%m%d}.log'

$toolPath = $configFile.Settings.Tool.ToolPath

# Basic log settings
Set-LoggingDefaultLevel -Level $logLevel
Add-LoggingTarget -Name File -Configuration @{Path = $logFile }

Write-Log -Level INFO -Message "============================== PICTURE ANALYSE STARTED =============================="
Write-Log -Level INFO -Message "Getting picture folder."

# User input of folder with jpg pictures 
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.rootfolder = "MyComputer"
if ($foldername.ShowDialog() -eq "OK") {
    $folder += $foldername.SelectedPath
}
Set-Location $folder
$txt = 'Folder: ' + $folder + ' choosed.'
Write-Log -Level INFO -Message $txt

# Getting picture tags from MS Azure service
Write-Log -Level INFO "Getting Picture Tags"
foreach ($pic in $(Get-ChildItem -Path $folder -Filter *.jpg)) {
    [string]$file = $pic.FullName
    #Write-Log -Level DEBUG -Message $file
    $tags = Get-ImageTag -Path $file

    $validTags = $tags.tags | Where-Object { $_.confidence -gt 0.6 } 
    $txt = 'Found ' + $validTags.Length + ' valid Tags for ' + $file
    Write-Log -Level INFO -Message $txt

    Write-Log -Level INFO -Message "Setting Picture Tags"
    foreach ($tag in $validTags) {
        $tagName = $tag.Name
        $vargs = '-keywords+="' + $tagName.ToUpper() + '" -overwrite_original ' + $pic.FullName 
        $txt = 'ARGS: ' + $vargs
        Write-Log -Level INFO -Message $txt
       $command = $toolPath + 'exiftool.exe ' + $vargs
       Invoke-Expression $command
    }
}

Write-Log -Level INFO -Message "====================================================================================="
Wait-Logging 

Set-Location $myDir