$formalLines = Import-Csv -Path "$PsScriptRoot\anniversary_formals.csv"
"Loaded $($formalLines.get_count()) formal anniversary words"

foreach ($formalLine in $formalLines) {
    # Left S's after F and V, and before many consonants
    $formalLine.formal = $formalLine.formal -replace 's-(([aie23]*-)?[oufvnmkgtd])', 's2-$1'
    $formalLine.formal = $formalLine.formal -replace '([fv])-s', '$1-s2'
}
$formalLines | Sort-Object {$_.word} | Select-Object -Property @('word','formal','lazy','keyer','usage','hint') | Export-Csv -Path "$PSScriptRoot\anniversary_refined.csv" -NoTypeInformation
