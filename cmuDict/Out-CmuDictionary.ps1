Function Out-CmuDictionary {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$outline
    )
    Begin{
        $usageFactor = 3
        $dictFile = "$PSScriptRoot\..\scripts\cmu_dictionary.ahk"
        Write-Host ("Writing finalized CMU outlines into a new dictionary at $dictFile")
        "; Auto generated $(Get-Date)" | Set-Content -Path $dictFile
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

    ":XC:$outline::Expand(`"$word`")" | Add-Content -Path $dictFile
    
    $capOutline = $outline -ireplace '^(\w)', "$($outline.substring(0,1).ToUpper())"
    $capWord = $word -ireplace '^(\w)', "$($word.substring(0,1).ToUpper())"
    if (-not ($word -ceq $capWord)) {
        ":XC:$capOutline::Expand(`"$capWord`")" | Add-Content -Path $dictFile
    }
}