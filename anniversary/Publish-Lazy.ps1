$usageLines = Import-Csv -Path "$PsScriptRoot\anniversary_usages.csv"
"Loaded $($usageLines.get_count()) usage-sorted anniversary words"

Function Convert-FormalToLazy {
    param (
        $word,
        $formal
    )
    
    $formal = $formal -replace '-h$', '-g'
    $formal = $formal -replace '-ng$', '-g'
    $formal = $formal -replace 'sh', 'z'
    $formal = $formal -replace 'ch', 'c'
    $formal = $formal -replace 'th', 'h'
    $formal = $formal -replace 'mn', 'mm'
    $formal = $formal -replace 'td', 'dd'
    $formal = $formal -replace 'ea', 'e'
    $formal = $formal -replace 'e-u', 'u'
    $formal = $formal -replace 'a-u', 'w'
    $formal = $formal -replace 'o-e', 'y'
    if ($word -match 'qu') {
        if ($word -match 'que(ly)$') {
            $formal = $formal -replace 'k([^k]*)$', 'q$1'
        } elseif ($word -notmatch '^con') {
            $formal = $formal -replace '^([^k]*)k', '$1q'
        } else {
            $formal = $formal -replace 'k([^k]*)$', 'q$1'
        }
        $formal = $formal -replace 'q-w', 'q'
    }
    if ($word -imatch '^ex') {
        $formal = $formal -replace '^e-s', 'x'
    }
    if ($word -imatch 'x') {
        $formal = $formal -replace '^([^k]*)k-s', '$1x'
    }
    if ($word -match '^an?$') {
        $formal = 'hk1'
    }
    if ($word -imatch '^i$') {
        $formal = 'ik1'
    }

    # Now strip non-words and digits 
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