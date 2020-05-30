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
        $clearOutlineMarkers = New-Object System.Collections.Hashtable  # This makes a case sensitive hash
    }
    Process{
        $ncoProgressIndex++
        Write-Progress -id 2 -Activity "Create clear outline $ncoProgressIndex of $($outlines.get_count())" -PercentComplete (100*$ncoProgressIndex/$outlines.get_count())
        Write-Verbose ("Creating clear outlines for $($outline.word)")
        $clearOutline = $outline.outline -replace '1$', ''
        Write-Verbose ("Testing $clearOutline")
        if ((-not $usageWords.ContainsKey($clearOutline)) -or ($usageWords[$clearOutline] -gt [int]$outline.usage * $usageFactor)) { 
            Write-Verbose ("No word conflicts for $($clearOutline)")

            # Bug: u:you and U:under conflict. We need to make sure u and U return the same word, and it should be "you".
                # Correct this by tracking newly created clear outlines and checking for them later
                # If this clear outline exists or its first character lowered twin, don't add it 
            $firstCharLoweredOutline = $clearOutline -ireplace '^(\w)', "$($clearOutline.substring(0,1).ToLower())"
            if ((-not $clearOutlineMarkers.ContainsKey($firstCharLoweredOutline)) -and (-not $clearOutlineMarkers.ContainsKey($clearOutline))) { 
                # Cleared of possible previous lowered outlines
                # If this outline is the most frequently used (ends in 1) and does not conflict with an existing word, add it as a clear 
                "$clearOutline,$($outline.word),$($outline.usage)" | Add-Content -Path $outlinesFile
            
                # Add this new outline to tracking 
                if (-not $clearOutlineMarkers.ContainsKey($clearOutline)) {
                    $clearOutlineMarkers[$clearOutline] = 1
                } else {
                    $clearOutlineMarkers[$clearOutline] = $clearOutlineMarkers[$clearOutline] + 1
                }
            } else {
                Write-Verbose ("A lowered version of $($clearOutline) already exists. Skipping the add.")
            }
        } else {
            Write-Verbose ("Blocking word conflict for $($clearOutline)")
        }
    }
    End{
        Write-Host ("Done Adding clear outlines to Outlines after $((New-TimeSpan -Start $ncoStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

