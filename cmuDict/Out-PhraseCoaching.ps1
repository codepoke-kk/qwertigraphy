$phrasedWords = @{}
$ignoreWordsPhrasedLessThan = 3

Function Out-PhraseCoaching {
    [CmdletBinding()]
    Param (
         $source,
         $wordSource,
         $destination
    )
    
    $usageFactor = 3
    Write-Host ("Writing phrase coaching tips into a new coach file at $destination")
    "; Auto generated $(Get-Date)" | Set-Content -Path $destination
    $opcProgressIndex = 0
    $opcStartTime = Get-Date
    
    $currentPhrase = ""
    $currentOutlines = New-Object System.Collections.ArrayList

    $dictionaryLines = Get-Content -Path $source | Select-String "^[:]" 
    foreach ($dictionaryLine in $dictionaryLines) {
        $opcProgressIndex++
        Write-Progress -id 2 -Activity "Output phrase coaching entry $opcProgressIndex of $($dictionaryLines.count)" -PercentComplete (100*$opcProgressIndex/$dictionaryLines.Count)
        $trash, $casedOutline, $newPhrase = $dictionaryLine -split ':C?:'
        $outline = $casedOutline -ireplace '^(\w)', "$($casedOutline.substring(0,1).ToLower())"
        Write-Verbose ("Accumulating $outline under $newPhrase")
        if ($newPhrase -ine $currentPhrase) {
            if ($currentPhrase.length) {
                $currentOutlines.Sort()
                if ($currentOutlines[0].length -eq 0) {
                    Write-Host ("dying with $dictionaryLine and $currentPhrase")
                } else {
                    Out-Coachphrase -coachFile $destination -phrase $currentPhrase -coachableOutlines $($currentOutlines -join ',') -savings ($currentPhrase.length - $currentOutlines[0].length)  -power ($currentPhrase.length / $currentOutlines[0].length)
                    Add-PhrasedWords -phrase $currentPhrase
                }
                $currentOutlines.Clear()
                $currentOutlines.Add($outline) | Out-Null
            }
            $currentPhrase = $newPhrase
        } else {
            if (-not $currentOutlines.Contains($outline)) {
                $currentOutlines.Add($outline) | Out-Null
            }
        }
    }
    $currentOutlines.Sort()
    Out-Coachphrase -coachFile $destination -phrase $currentPhrase -coachableOutlines $($currentOutlines -join ',') -savings ($currentPhrase.length - $currentOutlines[0].length)  -power ($currentPhrase.length / $currentOutlines[0].length)
    Add-PhrasedWords -phrase $currentPhrase

    $wordCoachingLines = Get-Content -Path $wordSource | Select-String "^[^;]" 
    for ($wordCoachingLinesIndex = 0; $wordCoachingLinesIndex -lt $wordCoachingLines.Count; $wordCoachingLinesIndex++) {
        Write-Progress -id 2 -Activity "Output word coaching into phrase coaching dictionary $wordCoachingLinesIndex of $($wordCoachingLines.count)" -PercentComplete (100*$wordCoachingLinesIndex/$wordCoachingLines.Count)
        $line = $wordCoachingLines[$wordCoachingLinesIndex]
        if ($line -imatch '^:\*b0:(\w+)\W::') {
            $word = $Matches.1 
            if ((-not $phrasedWords.ContainsKey($word)) -or ($phrasedWords.$word -gt $ignoreWordsPhrasedLessThan)) {
                $line | Add-Content -Path $destination
                $wordCoachingLinesIndex++
                $wordCoachingLines[$wordCoachingLinesIndex] | Add-Content -Path $destination
                $wordCoachingLinesIndex++
                $wordCoachingLines[$wordCoachingLinesIndex] | Add-Content -Path $destination
            } else {
                Write-Verbose ("Skipping $word")
            }
        }
    }


    Write-Host ("Ending writing of phrase_coaching.ahk after $((New-TimeSpan -Start $opcStartTime -End (Get-Date)).TotalSeconds) seconds")
}

Function Add-PhrasedWords {
    param (
        $phrase
    )

    $words = $phrase -split ' '
    for ($wordIndex = 0; $wordIndex -lt ($words.count - 1); $wordIndex++) {
        $word = $words[$wordIndex]
        if (-not $phrasedWords.ContainsKey($word)) {
            $phrasedWords.Add($word, 1)
        } else {
            $phrasedWords.$word++
        }
    }
}

Function Out-Coachphrase {
    param (
        $coachFile,
        $coachableOutlines,
        $phrase,
        $savings,
        $power
    )

    
    ":*b0:$phrase ::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $phrase")
    "`tCoachOutline(`"$coachableOutlines`",`"$phrase`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    ":*b0:$phrase,::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $phrase")
    "`tCoachOutline(`"$coachableOutlines`",`"$phrase`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    ":*b0:$phrase.::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $phrase")
    "`tCoachOutline(`"$coachableOutlines`",`"$phrase`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    
}