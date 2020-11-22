$keyedLines = Import-Csv -Path "$PsScriptRoot\anniversary_keyeds.csv"
"Loaded $($keyedLines.get_count()) keyed anniversary words"


foreach ($keyedLine in ($keyedLines | Sort-Object {[int]($_.usage)})) {
    $keyedLine.hint = "$($keyedLine.word) = $($keyedLine.lazy) ($($keyedLine.formal)) [$($keyedLine.word.Length - $keyedLine.lazy.Length)]"
}
$keyedLines | Sort-Object {[int]($_.usage)} | Select-Object -Property @('word','formal','lazy','keyer','usage','hint') | Export-Csv -Path "$PSScriptRoot\anniversary_core.csv" -NoTypeInformation