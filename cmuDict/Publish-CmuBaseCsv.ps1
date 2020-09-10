$stepsIndex = 0
$stepsTotal = 3

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
. $PSScriptRoot\New-CmuBaseCsvObject.ps1
. $PSScriptRoot\Add-FormalOutline.ps1
. $PSScriptRoot\Add-LazyOutline.ps1
. $PSScriptRoot\Add-WordUsage.ps1

### Begin tranforming the CMU dictionary into a set of simple Gregg outlines
$stepsIndex = 2;Write-Progress -id 1 -Activity "Write initial CMU Lines and reimport $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
"Loaded functions"
# CMUObject was once a custom object. It's now a CSV string with 5 values
$cmuLines = $rawCmuWordsLines | New-CmuBaseCsvObject | Add-FormalOutline | Add-LazyOutline | Add-WordUsage
# Cache the collection of values to file with each outline created cleanly by rule
$outlinesFile = "$PSScriptRoot\..\temp\outlines_initial.csv"
'word,pronunciation,formal,lazy,usage,hint,keyer' | Set-Content -Path $outlinesFile
$cmuLines | Add-Content -Path $outlinesFile
# Reload them as CSV objects 
$cmus = Import-CSV -Path $outlinesFile

$stepsIndex = 3;Write-Progress -id 1 -Activity "Add disambiguating keyers to lazy outlines $stepsIndex of $stepsTotal" -PercentComplete (100*$stepsIndex/$stepsTotal)
$keyers = @('o','u','i','a','e','y','w','oo','uu','ii','aa','ee','yy','ww','o1','u1','i1','a1','e1','y1','w1','o2','u2','i2','a2','e2','y2','w2','o3','u3','i3','a3','e3','y3','w3')
$usedOutlines = New-Object System.Collections.Hashtable

$usageFactor = 3
Foreach ($cmu in ($cmus | Sort {[int]$_.usage})) {
    $cmu.word = $cmu.word.ToLower()
    $used = $false
    if ((-not $usedOutlines.ContainsKey($cmu.lazy)) -and (-not $usageWords.ContainsKey($cmu.lazy))) {
        # This lazy outline has not been used and it is not a word
        $usedOutlines.Add($cmu.lazy, $cmu.word)
        $used = $true
    } elseif ((-not $usedOutlines.ContainsKey($cmu.lazy)) -and ($usageWords[$cmu.lazy] -gt [int]$cmu.usage * $usageFactor)) {
        # This lazy outline is unused, but it is a word. Decide whether to use it 
        $usedOutlines.Add($cmu.lazy, $cmu.word)
        $used = $true
    } 
    
    if (-not $used) {
        # This lazy outline cannot be used, so find a substitute
        Foreach ($keyer in $keyers) {
            if (-not $usedOutlines.ContainsKey("$($cmu.lazy)$keyer")) {
                if (-not $usageWords.ContainsKey("$($cmu.lazy)$keyer")) {
                    $usedOutlines.Add("$($cmu.lazy)$keyer", $cmu.word)
                    $cmu.keyer = $keyer
                    $cmu.lazy = "$($cmu.lazy)$keyer"
                    break
                } elseif ($usageWords["$($cmu.lazy)$keyer"] -gt [int]$cmu.usage * $usageFactor * 2) {
                    $usedOutlines.Add("$($cmu.lazy)$keyer", $cmu.word)
                    $cmu.keyer = $keyer
                    $cmu.lazy = "$($cmu.lazy)$keyer"
                    break
                }
            }
        }
    }
    $cmu.hint = "$($cmu.word) = $($cmu.lazy) ($($cmu.formal))  [$($cmu.word.Length - $cmu.lazy.Length)]"
}

$cmus | Sort {[int]$_.usage} | Select-Object -Property @('word','formal','lazy','keyer','usage','hint') | Export-Csv -Path "$PSScriptRoot\..\scripts\outlines_final.csv" -NoTypeInformation


"Ended $(Get-Date)"