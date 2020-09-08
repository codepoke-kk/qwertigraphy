Function Out-CmuBaseCsv {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$outline
    )
    Begin{
        $usageFactor = 3
        $dictFile = "$PSScriptRoot\..\scripts\cmu_base.csv"
        Write-Host ("Writing base CMU objects into a new dictionary at $dictFile")
        "formal,lazy,word,frequency,hint" | Set-Content -Path $dictFile
        $ocdProgressIndex = 0
        $ocdStartTime = Get-Date
    }
    Process{
        $ocdProgressIndex++
        Write-Progress -id 2 -Activity "Output entry $ocdProgressIndex of $($outlines.count)" -PercentComplete (100*$ocdProgressIndex/$outlines.Count)
        Write-Verbose ("Writing $($outline.outline)")
        Out-Outline -dictFile $dictFile -word $outline.word.toLower() -outline $outline.outline 
    }
    End{
        Write-Host ("Ending writing of cmu_dictionary.ahk after $((New-TimeSpan -Start $ocdStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

Function Out-Outline {
    param (
        $dictFile,
        $outline,
        $word
    )

    "$outline,,$word,," | Add-Content -Path $dictFile
}