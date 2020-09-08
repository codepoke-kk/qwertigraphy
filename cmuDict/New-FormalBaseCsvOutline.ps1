Function New-FormalOutline {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Formal Gregg Outline from CMU Object to Outlines Hashtable")
        $nfoProgressIndex = 0
        $nfoStartTime = Get-Date
        $outlinesFile = "$PsScriptRoot\..\temp\outlines.csv"
    }
    Process{
        $nfoProgressIndex++
        Write-Progress -id 2 -Activity "Create formal outline $nfoProgressIndex of $($rawCmuWordsLines.get_count())" -PercentComplete (100*$nfoProgressIndex/$rawCmuWordsLines.get_count())
        Write-Verbose ("Creating formal outline for $($cmu.word)")
        if (-not $outlineMarkers.ContainsKey($cmu.formal)) {
            $outlineMarkers[$cmu.formal] = 1
        } else {
            $outlineMarkers[$cmu.formal] = $outlineMarkers[$cmu.formal] + 1
        }
        Write-Verbose ("Marking $($cmu.formal) as $($outlineMarkers[$cmu.formal])")
        "$($cmu.formal)$($outlineMarkers[$cmu.formal]),$($cmu.word),$($cmu.usage),$($cmu.hint)" | Add-Content -Path $outlinesFile
    }
    End{
        Write-Host ("Done Adding Formal Gregg Outlines to Outlines after $((New-TimeSpan -Start $nfoStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

