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
        $lazyOutline = ConvertTo-LazyGreggOutline -formal $formal -word $word
        "$cmu,$($lazyOutline.trim())"
    }
    End{
        Write-Host ("Done Adding Lazy Gregg Outlines to CMU Object after $((New-TimeSpan -Start $aloStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}


Function ConvertTo-LazyGreggOutline {
    [CmdletBinding()]
    param (
        $formal, 
        $word
    )
 
    # Whole words
    $formal = $formal.toLower()

    # Vowels
    $formal = $formal -ireplace 'ea', 'e'
    $formal = $formal -ireplace 'ao', 'w'
    $formal = $formal -ireplace 'au', 'w'
    $formal = $formal -ireplace 'eu', 'u'

    # Consonant sets
    if ($word -imatch 'x') {
        $formal = $formal -ireplace 'es', 'x'
    }
    if ($word -imatch 'qu') {
        $formal = $formal -ireplace 'k', 'q'
    }

    # Prefixes
    $formal = $formal -ireplace 'pr(e|o)', 'pr'
    $formal = $formal -ireplace 'per', 'pr'

    $formal
}
