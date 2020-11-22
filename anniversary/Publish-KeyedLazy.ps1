$lazyLines = Import-Csv -Path "$PsScriptRoot\anniversary_lazies.csv"
"Loaded $($lazyLines.get_count()) lazy anniversary words"

$usageWords = . "$PsScriptRoot\Read-UsageRanking.ps1"

$keyers = @('','o','u','i','e','a','w','y')
Function Get-Keyer {
    param (
        $usage,
        $lazy
    )
    
    foreach ($keyer in $keyers) {
        $keyedForm = "$lazy$keyer"

        # Check to see whether this is already a word, and if so, a much-used word
        if ($usageWords.ContainsKey($keyedForm)) {
            if ($usage -gt ($usageWords[$keyedForm] / 5)) {
                continue
            }
        }
        if (-not $keyedForms.ContainsKey($keyedForm)) {
            $keyedForms.Add($keyedForm, $true)
            Return $keyer
        }
    }
    $keyerIndex = 1
    Do {
        $keyer = "k$keyerIndex"
        $keyedForm = "$lazy$keyer"
        if (-not $keyedForms.ContainsKey($keyedForm)) {
            $keyedForms.Add($keyedForm, $true)
            Return $keyer
        }
        $keyerIndex++
    } While ($true) 
}

$keyedForms = @{}
foreach ($lazyLine in ($lazyLines | Sort-Object {[int]($_.usage)})) {
    #if ($lazyLine.word -eq 'his') {
    #    Write-Host "Found his"
    #}
    $keyer = Get-Keyer -usage ([int]($lazyLine.usage)) -lazy $lazyLine.lazy
    $lazyLine.keyer = $keyer
    $lazyLine.lazy = "$($lazyLine.lazy)$keyer"
    $lazyLine.usage = [int]($lazyLine.usage)
}
$lazyLines | Sort-Object {$_.usage}| Export-Csv -Path "$PSScriptRoot\anniversary_keyeds.csv" -NoTypeInformation