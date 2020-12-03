$usageLines = Import-Csv -Path "$PsScriptRoot\anniversary_usages.csv"
"Loaded $($usageLines.get_count()) usage-sorted anniversary words"

Function Convert-FormalToLazy {
    param (
        $word,
        $formal
    )
    
    $formal = $formal -replace '-h$', '-g'
    $formal = $formal -replace 'sh', 'z'
    $formal = $formal -replace 'ch', 'c'
    $formal = $formal -replace 'th', 'h'
    $formal = $formal -replace 'e-u', 'u'
    $formal = $formal -replace 'a-u', 'w'
    $formal = $formal -replace 'o-e', 'y'
    if ($word -match '^qu') {
        $formal = $formal -replace '^k', 'q'
    }
    if ($word -match '^an?$') {
        $formal = 'hk1'
    }
    if ($word -imatch '^i$') {
        $formal = 'ik1'
    }
    $formal = $formal -replace '\W', ''
    $formal = $formal -replace '\d', ''
    # Straight hacks
    if ($word -match '^think') {
        $formal = $formal -replace '^hg', 'hh'
    }
    $formal
}

$lazyForms = @{}
foreach ($usageLine in $usageLines) {
    $lazy = Convert-FormalToLazy -word $usageLine.word -formal $usageLine.formal
    $usageLine.lazy = $lazy
    $usageLine.usage = [int]($usageLine.usage)
}
$usageLines | Sort-Object {$_.usage}| Export-Csv -Path "$PSScriptRoot\anniversary_lazies.csv" -NoTypeInformation