<#
First complex method. Any "first" outline, the outline ends in 1, might be able to be a clear outline
Clear outlines require no number to be typed, and we want as many as possible
If the outline with the 1 stripped from the end, the "clear" outline, doesn't match an existing word,
or if the existing word it matches is much less frequently used, then make this a clear outline.
As an example, "ore1" is the first outline for already. Already is used much more frequently than "ore"
so allow that clear brief and force the user to type ore with a control character
#>

Function New-ClearOutline {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$outline
    )
    Begin{
        Write-Host ("Adding Clear Gregg Outline from Base Outline to Outlines File")
        $ncoProgressIndex = 0
        $ncoStartTime = Get-Date
        $usageFactor = 3
    }
    Process{
        $ncoProgressIndex++
        Write-Progress -id 2 -Activity "Create clear outline $ncoProgressIndex of $($outlines.get_count())" -PercentComplete (100*$ncoProgressIndex/$outlines.get_count())
        Write-Verbose ("Creating clear outlines for $($outline.word)")
        $clearOutline = $outline.outline -replace '1$', ''
        Write-Verbose ("Testing $clearOutline")
        if ((-not $usageWords.ContainsKey($clearOutline)) -or ($usageWords[$clearOutline] -gt [int]$outline.usage * $usageFactor)) { 
            Write-Verbose ("No word conflicts for $($clearOutline)")
            # If this outline is the most frequently used (ends in 1) and does not conflict with an existing word, add it as a clear outline
            "$clearOutline,$($outline.word),$($outline.usage)" | Add-Content -Path $outlinesFile
        } else {
            Write-Verbose ("Blocking word conflict for $($clearOutline)")
        }
    }
    End{
        Write-Host ("Done Adding clear outlines to Outlines after $((New-TimeSpan -Start $ncoStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

