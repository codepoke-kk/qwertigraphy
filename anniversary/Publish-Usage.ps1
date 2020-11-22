$formalLines = Import-Csv -Path "$PsScriptRoot\anniversary_formals.csv"
"Loaded $($formalLines.get_count()) formal anniversary words"

$usageWords = . "$PsScriptRoot\Read-UsageRanking.ps1"

$unusedIndex = 70000
foreach ($formalLine in $formalLines) {
    if ($usageWords.ContainsKey($formalLine.word)) {
        $formalLine.usage = $usageWords[$formalLine.word]
    } else {
        $formalLine.usage = $unusedIndex++
    }
}
$formalLines | Sort-Object {$_.usage}| Export-Csv -Path "$PSScriptRoot\anniversary_usages.csv" -NoTypeInformation
