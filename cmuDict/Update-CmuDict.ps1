$stepsIndex = 0
$stepsTotal = 7

"Began $(Get-Date)"

$stepsIndex = 1;Write-Progress -id 1 -Activity "Create new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)

$rawCmuWordsLines = . $PSScriptRoot\Read-RawCmuDict.ps1
"Loaded $($rawCmuWordsLines.get_count()) raw CMU words"
$trainingWords = . $PSScriptRoot\Read-TrainingWords.ps1
"Loaded $($trainingWords.get_count()) training words"
$usageWords = . $PSScriptRoot\Read-UsageRanking.ps1
"Loaded $($usageWords.get_count()) usage words"

. $PSScriptRoot\New-CmuObject.ps1
. $PSScriptRoot\Add-FormalOutline.ps1
. $PSScriptRoot\Add-LazyOutline.ps1
. $PSScriptRoot\Add-WordUsage.ps1
. $PSScriptRoot\New-FormalOutline.ps1
. $PSScriptRoot\New-LazyOutline.ps1
. $PSScriptRoot\New-ClearOutline.ps1
. $PSScriptRoot\Out-CmuDictionary.ps1
. $PSScriptRoot\Out-CmuCoaching.ps1

$stepsIndex = 2;Write-Progress -id 1 -Activity "Write initial CMU Lines and reimport $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
"Loaded functions"
$cmuLines = $rawCmuWordsLines | New-CmuObject | Add-FormalOutline | Add-LazyOutline | Add-WordUsage
'word,pronunciation,formal,lazy,usage' | Set-Content -Path "$PSScriptRoot\..\temp\cmuLines.csv"
$cmuLines | Add-Content -Path "$PSScriptRoot\..\temp\cmuLines.csv"
$cmus = Import-CSV -Path "$PSScriptRoot\..\temp\cmuLines.csv"


$stepsIndex = 3;Write-Progress -id 1 -Activity "Create numbered outlines file $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
# Keep a count of how many times we've overloaded a given outline
$outlineMarkers = New-Object System.Collections.Hashtable  # This makes a case sensitive hash
$outlinesFile = "$PsScriptRoot\..\temp\outlines.csv"
'outline,word,usage' | Set-Content -Path $outlinesFile
$cmus | Sort {[int]$_.usage} | New-LazyOutline | New-FormalOutline


$stepsIndex = 4;Write-Progress -id 1 -Activity "Retrieve outlines as CSV objects $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines = Import-CSV -Path $outlinesFile


$stepsIndex = 5;Write-Progress -id 1 -Activity "Create clear outlines $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines | Where-Object {$_.outline -imatch '\w1$'} | New-ClearOutline #-Verbose
$outlines = Import-CSV -Path $outlinesFile


"Outputting dictionary"
$stepsIndex = 6;Write-Progress -id 1 -Activity "Output new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines | Sort {$_.word} | Out-CmuDictionary # -Verbose


$stepsIndex = 7;Write-Progress -id 1 -Activity "Create new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
Out-CmuCoaching -source "$PSScriptRoot\..\scripts\cmu_dictionary.ahk" -destination "$PSScriptRoot\..\scripts\cmu_coaching.ahk" #-Verbose


"Ended $(Get-Date)"