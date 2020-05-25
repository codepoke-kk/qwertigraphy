Function Add-LazyOutline {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Lazy Gregg Outline to CMU Object")
        $aloProgressIndex = 0
        $aloStartTime = Get-Date
    }
    Process{
        $word,$pronunciation,$formal = $cmu -split ','
        Write-Verbose ("Converting $formal to lazy")
        $lazyOutline = ConvertTo-LazyGreggOutline -formal $formal
        "$cmu,$lazyOutline"
    }
    End{
        Write-Host ("Done Adding Lazy Gregg Outlines to CMU Object after $((New-TimeSpan -Start $aloStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}


Function ConvertTo-LazyGreggOutline {
    [CmdletBinding()]
    param (
        $formal
    )
 
    # Whole words
    $formal = $formal.toLower()

    $formal
}
