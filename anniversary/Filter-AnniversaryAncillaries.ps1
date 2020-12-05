$cores = Import-Csv -Path "$PsScriptRoot\anniversary_core.csv"
"Loaded $($cores.get_count()) core anniversary words"
$moderns = Import-Csv -Path "$PsScriptRoot\anniversary_modern.csv"
"Loaded $($moderns.get_count()) modern anniversary words"
$cmus = Import-Csv -Path "$PsScriptRoot\anniversary_cmu.csv"
"Loaded $($cmus.get_count()) cmu anniversary words"

$coresHash = @{}
foreach ($core in $cores) {
    $coresHash.Add($core.word, $core) 
}

$modernsPurged = New-Object System.Collections.ArrayList
foreach ($modern in $moderns) {
    #$conflicts = @($cores | Where-Object {$_.word -eq $modern.word})
    if (-not $coresHash.ContainsKey($modern.word)) {
        $modernsPurged.Add($modern) | Out-Null
    }
}

$cmusPurged = New-Object System.Collections.ArrayList
foreach ($cmu in $cmus) {
    #$conflicts = @($cores | Where-Object {$_.word -eq $cmu.word})
    if (-not $coresHash.ContainsKey($cmu.word)) {
        $cmusPurged.Add($cmu) | Out-Null
    }
}

$cmusPurged | Sort-Object {([int]$_.usage)} | Select-Object -Property @('word','formal','lazy','keyer','usage','hint') | Export-Csv -Path "$PSScriptRoot\anniversary_cmu_purged.csv" -NoTypeInformation

