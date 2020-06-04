$stepsIndex = 0
$stepsTotal = 7

"Began $(Get-Date)"

$stepsIndex = 1;Write-Progress -id 1 -Activity "Create new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)

### Load all the raw data we'll need to build the final dictionary and coaching file
# Read the Carnegie Mellon University pronunciation dictionary
$rawCmuWordsLines = . $PSScriptRoot\Read-RawCmuDict.ps1
"Loaded $($rawCmuWordsLines.get_count()) raw CMU words"
# Load the Wikipedia list of words in frequency order 
$usageWords = . $PSScriptRoot\Read-UsageRanking.ps1
"Loaded $($usageWords.get_count()) usage words"

# Preload a number of functions we'll need to finish this job, each stored in separate files. 
# I could use a module, but this makes it easier to just work with one function
. $PSScriptRoot\New-CmuObject.ps1
. $PSScriptRoot\Add-FormalOutline.ps1
. $PSScriptRoot\Add-LazyOutline.ps1
. $PSScriptRoot\Add-WordUsage.ps1
. $PSScriptRoot\New-FormalOutline.ps1
. $PSScriptRoot\New-LazyOutline.ps1
. $PSScriptRoot\New-ClearOutline.ps1
. $PSScriptRoot\Out-CmuDictionary.ps1
. $PSScriptRoot\Out-CmuCoaching.ps1

### Begin tranforming the CMU dictionary into a set of simple Gregg outlines
$stepsIndex = 2;Write-Progress -id 1 -Activity "Write initial CMU Lines and reimport $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
"Loaded functions"
# CMUObject was once a custom object. It's now a CSV string with 5 values
$cmuLines = $rawCmuWordsLines | New-CmuObject | Add-FormalOutline | Add-LazyOutline | Add-WordUsage
# Cache the collection of values to file with each outline created cleanly by rule
'word,pronunciation,formal,lazy,usage' | Set-Content -Path "$PSScriptRoot\..\temp\cmuLines.csv"
$cmuLines | Add-Content -Path "$PSScriptRoot\..\temp\cmuLines.csv"
# Reload them as CSV objects 
$cmus = Import-CSV -Path "$PSScriptRoot\..\temp\cmuLines.csv"

### Take the simple lazy and formal outlines, and cache them to CSV after as numbered outlines by usage frequency priority
$stepsIndex = 3;Write-Progress -id 1 -Activity "Create numbered outlines file $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
# Use a hash to count how many times we've overloaded a given outline
$outlineMarkers = New-Object System.Collections.Hashtable  # This makes a case sensitive hash
$outlinesFile = "$PsScriptRoot\..\temp\outlines.csv"
'outline,word,usage' | Set-Content -Path $outlinesFile
# The 2 New- methods will write each outline to the CSV file with a number representing how many overloads this outline has seen
$cmus | Sort {[int]$_.usage} | New-LazyOutline | New-FormalOutline

### Pull back the outlines as CSV objects for easy handling
$stepsIndex = 4;Write-Progress -id 1 -Activity "Retrieve outlines as CSV objects $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines = Import-CSV -Path $outlinesFile

### Compare all priority 1 numbered outlines to existing English words and where possible make unnumbered outlines of them
$stepsIndex = 5;Write-Progress -id 1 -Activity "Create clear outlines $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines | Where-Object {$_.outline -imatch '\w1$'} | New-ClearOutline # -Verbose
# Pull back a fresh load of the outlines
$outlines = Import-CSV -Path $outlinesFile

### Write outlines by word order as an AHK script
"Outputting dictionary"
$stepsIndex = 6;Write-Progress -id 1 -Activity "Output new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$outlines | Sort {$_.word} | Out-CmuDictionary # -Verbose

### Write coaching lines by CMU dictionary order, which is word order
# Coaching is created by reading in every outline for a given word and listing them all in the tip
$stepsIndex = 7;Write-Progress -id 1 -Activity "Create new CMU Dictionary $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
Out-CmuCoaching -source "$PSScriptRoot\..\scripts\cmu_dictionary.ahk" -destination "$PSScriptRoot\..\scripts\cmu_coaching.ahk" #-Verbose


"Ended $(Get-Date)"