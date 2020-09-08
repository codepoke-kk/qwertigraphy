Function New-LazyOutline {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Lazy Gregg Outline from CMU Object to Outlines Hashtable")
        $nloProgressIndex = 0
        $nloStartTime = Get-Date
    }
    Process{
        $nloProgressIndex++
        Write-Progress -id 2 -Activity "Create lazy outline $nloProgressIndex of $($rawCmuWordsLines.get_count())" -PercentComplete (100*$nloProgressIndex/$rawCmuWordsLines.get_count())
        Write-Verbose ("Creating lazy outline for $($cmu.word)")
        if (-not $outlineMarkers.ContainsKey($cmu.lazy)) {
            $outlineMarkers[$cmu.lazy] = 1
        } else {
            $outlineMarkers[$cmu.lazy] = $outlineMarkers[$cmu.lazy] + 1
        }
        Write-Verbose ("Marking $($cmu.lazy) as $($outlineMarkers[$cmu.lazy])")
        "$($cmu.lazy)$($outlineMarkers[$cmu.lazy]),$($cmu.word),$($cmu.usage),$($cmu.hint)" | Add-Content -Path $outlinesFile
        
        # Only emit the $cmu to have a formal brief created if it's actually different, else let it stop here
        if ($cmu.lazy -cne $cmu.formal) {
            $cmu
        }
    }
    End{
        Write-Host ("Done Adding Lazy Gregg Outlines to Outlines after $((New-TimeSpan -Start $nloStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

