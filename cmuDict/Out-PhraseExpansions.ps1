
Function Out-PhraseExpansions {
    [CmdletBinding()]
    Param (
         $source,
         $destination
    )
    
    Write-Host ("Writing phrase expansions into a new file at $destination")
    "; Auto generated $(Get-Date)" | Set-Content -Path $destination
    $opeProgressIndex = 0
    $opeStartTime = Get-Date
    
    # This is grouped by last word, so we have to ingest and output
    $endings = New-Object System.Collections.Hashtable
    $phrases = New-Object System.Collections.Hashtable

    $dictionaryLines = Get-Content -Path $source | Select-String "^[:]" 
    foreach ($dictionaryLine in $dictionaryLines) {
        $opeProgressIndex++
        Write-Progress -id 2 -Activity "Output phrase expansion entry $opeProgressIndex of $($dictionaryLines.count)" -PercentComplete (100*$opeProgressIndex/$dictionaryLines.Count)
        $trash, $casedOutline, $phrase = $dictionaryLine -split ':C?:'
        $outline = $casedOutline.toLower()
        $phrase = $phrase.toLower()
        # "$ending of $phrase under $outline"
        if (-not $phrases.ContainsKey($phrase)) {
            $phrases[$phrase] = $outline
        } else {
            if ($phrases[$phrase] -notmatch "\b$outline\b") {
                $phrases[$phrase] = "$($phrases[$phrase]),$outline"
            }
        }
    }
    foreach ($phrase in $phrases.keys) {
        $ending = ($phrase -split ' ')[-1]
        if (-not $endings.ContainsKey($ending)) {
            $endings[$ending] = New-Object System.Collections.Hashtable
        }
        $endings[$ending].Add($phrase, $phrases[$phrase])
    }

    # Create phrase expansions arrays
    # phraseMapping := Object("lb", "will be", "kb", "can be")
    # phraseEndings["be"] := phraseMapping
    
    "; Auto generated $(Get-Date)" | Set-Content -Path $destination
    "LoadPhraseExpansions() {" | Add-Content -Path $destination
    "global phraseEndings" | Add-Content -Path $destination
    foreach ($ending in $endings.Keys) {
        $phraseMapping = "phraseMapping := Object("
        foreach ($phrase in $endings[$ending].Keys) {
            # "$ending for $phrase is $($phrases[$phrase])"
            $phraseMapping = "$($phraseMapping)`"$($phrases[$phrase])`", `"$phrase`","
        }
        $phraseMapping = $phraseMapping -replace ',$', ")"
        "$phraseMapping" | Add-Content -Path $destination
        "phraseEndings[`"$ending`"] := phraseMapping" | Add-Content -Path $destination
    }
    
    "}" | Add-Content -Path $destination
#    Out-Coachphrase -coachFile $destination -phrase $currentPhrase -coachableOutlines $($currentOutlines -join ',') -savings ($currentPhrase.length - $currentOutlines[0].length)  -power ($currentPhrase.length / $currentOutlines[0].length)
#    Add-PhrasedWords -phrase $currentPhrase

    Write-Host ("Ending writing of phrase_expansions.ahk after $((New-TimeSpan -Start $opeStartTime -End (Get-Date)).TotalSeconds) seconds")
}