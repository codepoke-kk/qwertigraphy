Function Out-PhraseCoaching {
    [CmdletBinding()]
    Param (
         $source,
         $destination
    )
    
    $usageFactor = 3
    Write-Host ("Writing phrase coaching tips into a new coach file at $destination")
    "; Auto generated $(Get-Date)" | Set-Content -Path $destination
    $opcProgressIndex = 0
    $opcStartTime = Get-Date
    
    $currentWord = ""
    $currentOutlines = New-Object System.Collections.ArrayList

    $dictionaryLines = Get-Content -Path $source | Select-String "^[:]" 
    foreach ($dictionaryLine in $dictionaryLines) {
        $opcProgressIndex++
        Write-Progress -id 2 -Activity "Output phrase coaching entry $opcProgressIndex of $($dictionaryLines.count)" -PercentComplete (100*$opcProgressIndex/$dictionaryLines.Count)
        $trash, $casedOutline, $newPhrase = $dictionaryLine -split '::'
        $outline = $casedOutline -ireplace '^(\w)', "$($casedOutline.substring(0,1).ToLower())"
        Write-Verbose ("Accumulating $outline under $newPhrase")
        if ($newPhrase -ine $currentWord) {
            if ($currentWord.length) {
                $currentOutlines.Sort()
                if ($currentOutlines[0].length -eq 0) {
                    Write-Host ("dying with $dictionaryLine and $currentWord")
                } else {
                    Out-Coachphrase -coachFile $destination -word $currentWord -coachableOutlines $($currentOutlines -join ',') -savings ($currentWord.length - $currentOutlines[0].length)  -power ($currentWord.length / $currentOutlines[0].length)
                }
                $currentOutlines.Clear()
                $currentOutlines.Add($outline) | Out-Null
            }
            $currentWord = $newPhrase
        } else {
            if (-not $currentOutlines.Contains($outline)) {
                $currentOutlines.Add($outline) | Out-Null
            }
        }
    }
    $currentOutlines.Sort()
    Out-Coachphrase -coachFile $destination -word $currentWord -coachableOutlines $($currentOutlines -join ',') -savings ($currentWord.length - $currentOutlines[0].length)  -power ($currentWord.length / $currentOutlines[0].length)

    Write-Host ("Ending writing of phrase_coaching.ahk after $((New-TimeSpan -Start $opcStartTime -End (Get-Date)).TotalSeconds) seconds")
}

Function Out-Coachphrase {
    param (
        $coachFile,
        $coachableOutlines,
        $word,
        $savings,
        $power
    )

    
    ":*b0:$word ::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $word")
    "`tCoachOutline(`"$coachableOutlines`",`"$word`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    ":*b0:$word,::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $word")
    "`tCoachOutline(`"$coachableOutlines`",`"$word`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    ":*b0:$word.::" | Add-Content -Path $coachFile
    Write-Verbose ("Adding savings and power for $word")
    "`tCoachOutline(`"$coachableOutlines`",`"$word`",$savings,$power)" | Add-Content -Path $coachFile
    "`tReturn" | Add-Content -Path $coachFile
    
}