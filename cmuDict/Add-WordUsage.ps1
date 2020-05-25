
Function Add-WordUsage {
    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Word Usage Ranking to CMU Object")
        $awuProgressIndex = 0
        $awuStartTime = Get-Date
        $currentRanking = 700000
    }
    Process{
        $word,$pronunciation,$formal,$lazy = $cmu -split ','
        if ($usageWords.ContainsKey($word)) {
            Write-Verbose ("Ranking $($word) as $($usageWords[$word])")
            $usage = $usageWords[$word]
        } else {
            ++$currentRanking
            Write-Verbose ("Ranking $($cmu.word) as $($currentRanking)")
            $usage = $currentRanking
        }
        "$cmu,$usage"
    }
    End{
        Write-Host ("Done Adding Word Usage to CMU Object after $((New-TimeSpan -Start $awuStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}

