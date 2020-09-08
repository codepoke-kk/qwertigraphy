Function New-BaseCsvOutline {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Gregg Outlines from CMU Object to Base CSV")
        $nloProgressIndex = 0
        $nloStartTime = Get-Date
    }
    Process{
        $nloProgressIndex++
        Write-Progress -id 2 -Activity "Create outline $nloProgressIndex of $($rawCmuWordsLines.get_count())" -PercentComplete (100*$nloProgressIndex/$rawCmuWordsLines.get_count())
        Write-Verbose ("Creating formal outline for $($cmu.word)")
        if (-not $outlineMarkers.ContainsKey($cmu.formal)) {
            $outlineMarkers[$cmu.formal] = 1
        } else {
            $outlineMarkers[$cmu.formal] = $outlineMarkers[$cmu.formal] + 1
        }
        Write-Verbose ("Marking $($cmu.formal) as $($outlineMarkers[$cmu.formal])")
        if (-not $cmu.formal -eq $cmu.lazy) {
            Write-Verbose ("Creating lazy outline for $($cmu.word)")
            if (-not $outlineMarkers.ContainsKey($cmu.lazy)) {
                $outlineMarkers[$cmu.lazy] = 1
            } else {
                $outlineMarkers[$cmu.lazy] = $outlineMarkers[$cmu.lazy] + 1
            }
        }
        Write-Verbose ("Marking $($cmu.lazy) as $($outlineMarkers[$cmu.lazy])")
        "$($cmu.formal)$($outlineMarkers[$cmu.formal]),$($cmu.lazy)$($outlineMarkers[$cmu.lazy]),$($cmu.word.toLower()),$($cmu.usage)" | Add-Content -Path $outlinesFile
    }
    End{
        Write-Host ("Done Adding Lazy Gregg Outlines to Outlines after $((New-TimeSpan -Start $nloStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

