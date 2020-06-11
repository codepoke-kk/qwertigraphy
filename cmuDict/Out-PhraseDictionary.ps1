Function Out-PhraseDictionary {
    [CmdletBinding()]
    Param (
         $source,
         $destination
    )

    $phrasesFile = $source

    $phrasesFileObject = Get-ChildItem -Path $phrasesFile
    $phrasesLines = $null # Uncomment me to get caching
    if (($phrasesLines.count) -and ($phrasesFileObject.LastWriteTime -lt $phrasesLastReadTime)) {
        # "Returning without doing anything"
        Return 
    }
    # "Returning fresh lines"
    $phrasesLastReadTime = Get-Date 

    $phrasesLines = Get-Content -Path $phrasesFile | Select-String "^[A-Z']"


    $usageFactor = 3
    $phraseDictFile = $destination
    Write-Host ("Writing finalized phrase outlines into a new dictionary at $phraseDictFile")
    "; Auto generated $(Get-Date)" | Set-Content -Path $phraseDictFile
    $opdProgressIndex = 0
    $opdStartTime = Get-Date
    foreach ($phrasesLine in $phrasesLines) {
            $opdProgressIndex++
            Write-Progress -id 2 -Activity "Output entry $opdProgressIndex of $($phrasesLines.count)" -PercentComplete (100*$opdProgressIndex/$phrasesLines.Count)
            $outline, $phrase = $phrasesLine -split ':'
            Write-Verbose ("Writing $outline")
            Out-PhraseOutline -phraseDictFile $phraseDictFile -phrase $phrase -outline $outline 
            if ($outline -cne $outline.ToLower()) {
                Out-PhraseOutline -phraseDictFile $phraseDictFile -phrase $phrase -outline $outline.ToLower() 
            }
        }

    Write-Host ("Ending writing of phrases.ahk after $((New-TimeSpan -Start $opdStartTime -End (Get-Date)).TotalSeconds) seconds")
}


Function Out-PhraseOutline {
    param (
        $phraseDictFile,
        $outline,
        $phrase
    )

    ":C:$outline::$phrase" | Add-Content -Path $phraseDictFile
    ":C:$($outline)0::$phrase" | Add-Content -Path $phraseDictFile
    
    $capOutline = $outline -ireplace '^(\w)', "$($outline.substring(0,1).ToUpper())"
    $capPhrase = $phrase -ireplace '^(\w)', "$($phrase.substring(0,1).ToUpper())"
    if (-not ($phrase -ceq $capPhrase)) {
        ":C:$capOutline::$capPhrase" | Add-Content -Path $phraseDictFile
        ":C:$($capOutline)0::$capPhrase" | Add-Content -Path $phraseDictFile
    }
}