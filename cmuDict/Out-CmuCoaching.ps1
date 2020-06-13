Function Out-CmuCoaching {
    [CmdletBinding()]
    Param (
         $source,
         $destination
    )
    
    $usageFactor = 3
    Write-Host ("Writing CMU coaching tips into a new coach file at $destination")
    "; Auto generated $(Get-Date)" | Set-Content -Path $destination
    $occProgressIndex = 0
    $occStartTime = Get-Date
    
    $currentWord = ""
    $currentOutlines = New-Object System.Collections.ArrayList

    $dictionaryLines = Get-Content -Path $source | Select-String "^[:]" 
    foreach ($dictionaryLine in $dictionaryLines) {
        $occProgressIndex++
        Write-Progress -id 2 -Activity "Output coaching entry $occProgressIndex of $($dictionaryLines.count)" -PercentComplete (100*$occProgressIndex/$dictionaryLines.Count)
        $trash, $casedOutline, $newExpansion = $dictionaryLine -split ':X?C?:'
        $trash, $newWord, $trash2 = $newExpansion -split '"'
        $outline = $casedOutline -ireplace '^(\w)', "$($casedOutline.substring(0,1).ToLower())"
        Write-Verbose ("Accumulating $outline under $word")
        if ($newWord -ine $currentWord) {
            if ($currentWord.length) {
                $currentOutlines.Sort()
                if ($currentOutlines[0].length -eq 0) {Write-Host ("dying with $dictionaryLine")}
                Out-Coachline -coachFile $destination -word $currentWord -coachableOutlines $($currentOutlines -join ',') -savings ($currentWord.length - $currentOutlines[0].length)  -power ($currentWord.length / $currentOutlines[0].length)
                $currentOutlines.Clear()
                $currentOutlines.Add($outline) | Out-Null
            }
            $currentWord = $newWord
        } else {
            if (-not $currentOutlines.Contains($outline)) {
                $currentOutlines.Add($outline) | Out-Null
            }
        }
    }
    $currentOutlines.Sort()
    Out-Coachline -coachFile $destination -word $currentWord -coachableOutlines $($currentOutlines -join ',') -savings ($currentWord.length - $currentOutlines[0].length)  -power ($currentWord.length / $currentOutlines[0].length)

    Write-Host ("Ending writing of cmu_coaching.ahk after $((New-TimeSpan -Start $occStartTime -End (Get-Date)).TotalSeconds) seconds")
}

Function Out-Coachline {
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