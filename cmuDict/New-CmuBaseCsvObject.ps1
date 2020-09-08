Function New-CmuBaseCsvObject {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$rawCmuLine
    )
    Begin{
        Write-Host ("Starting creation of New CMU Objects from raw key/value pairs")
        $ncoProgressIndex = 0
        $ncoStartTime = Get-Date
    }
    Process{
        $ncoProgressIndex++
        Write-Progress -id 2 -Activity "Create CMU Object $ncoProgressIndex of $($rawCmuWordsLines.get_count())" -PercentComplete (100*$ncoProgressIndex/$rawCmuWordsLines.get_count())
        Write-Verbose ("Got $rawCmuLine")
        $newCmuLine = "$($rawCmuLine -ireplace '  ', ',')"
        Write-Verbose ("Emitting $newCmuLine")
        $newCmuLine
    }
    End{
        Write-Host ("Ending creation of New CMU Objects $((New-TimeSpan -Start $ncoStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}