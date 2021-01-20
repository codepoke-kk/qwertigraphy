$dictionaryFile = "$PsScriptRoot\anniversary_source.txt"
$sourceDictionaryLines = Get-Content -Path $dictionaryFile

"Loaded $($sourceDictionaryLines.get_count()) source Gregg words"

$lineCount = 0

$started = $false
$outlines = New-Object System.Collections.ArrayList
# Manually inject the word "being" because we just need it 
$outlines.Add('b-h           being') | Out-Null
foreach ($sourceLine in $sourceDictionaryLines) {
    $lineCount++
    if ($sourceLine -eq '------------------------------------------------------------------------') {
        $started = $true
        Continue
    }
    if (-not $started) {Continue}
    if (-not $sourceline.length) {Continue}

    # Transformations to just plain correct errors in the original source 
    if ($sourceline -match '^a-b-u  ') {Continue}
    if ($sourceline -match 'this') {$sourceline = $sourceline -replace 'th-s', 'ths'}
    $sourceline = $sourceline -replace 'th20', 'th2)'
    $sourceline = $sourceline -replace 'n-j-e k-s/k-sh', 'n-j-e/k-s/k-sh'
    $sourceline = $sourceline -replace 'ths \(s1\)', 'ths     '
    $sourceline = $sourceline -replace 'condititon', 'condition'
    $sourceline = $sourceline -replace 'k/l \(k on line\)', 'k-u             '

    # $sourceline = $sourceline -replace 's-([oufvnmkgtd])', 's2-$1'
    $outlines.Add($sourceline) | Out-Null
}
$outlines | Set-Content -Path "$PsScriptRoot\anniversary_raw.txt"
