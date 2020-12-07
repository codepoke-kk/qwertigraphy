$formalLines = Import-Csv -Path "$PsScriptRoot\anniversary_formals.csv"
"Loaded $($formalLines.get_count()) formal anniversary words"

foreach ($formalLine in $formalLines) {
    # Left S's after F and V, and before many consonants
    $formalLine.formal = $formalLine.formal -replace 's-(([aie23]*-)?[oufvnmkgtd])', 's2-$1'
    $formalLine.formal = $formalLine.formal -replace '([fv])-s', '$1-s2'
    # PR, PL
    $formalLine.formal = $formalLine.formal -replace 'pr', 'pr'
    $formalLine.formal = $formalLine.formal -replace 'p-l', 'pl'
    # BR, BL 
    $formalLine.formal = $formalLine.formal -replace 'b-r', 'br'
    $formalLine.formal = $formalLine.formal -replace 'b-l', 'bl'
    # FR, FL 
    $formalLine.formal = $formalLine.formal -replace 'f-r', 'fr'
    $formalLine.formal = $formalLine.formal -replace 'f-l', 'fl'
}
$formalLines | Sort-Object {$_.word} | Select-Object -Property @('word','formal','lazy','keyer','usage','hint') | Export-Csv -Path "$PSScriptRoot\anniversary_refined.csv" -NoTypeInformation
