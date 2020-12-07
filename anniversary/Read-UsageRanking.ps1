$usageWordsFile = "$PsScriptRoot\wiki-100k.txt"
$priorityWordsFile = "$PsScriptRoot\priority_words.txt"
$priorityWordsLines = Get-Content -Path $priorityWordsFile | Select-String "^[^#]" 
$unprotectWordsFile = "$PsScriptRoot\unprotect_words.txt"
$unprotectWordsLines = Get-Content -Path $unprotectWordsFile | Select-String "^[^#]" 

$unprotectWords = New-Object System.Collections.Hashtable
foreach ($unprotectWordsLine in $unprotectWordsLines) {
    $unprotectWords.Add($unprotectWordsLine.toString().toLower(), $true)
}

$usageWordsFileObject = Get-ChildItem -Path $usageWordsFile
$usageWordsLines = Get-Content -Path $usageWordsFile | Select-String "^[^#]" 
$usageWords = @{}
$usageWordIndex = 0
# Loop across the priority words first and add them first so they have higher priority
foreach ($usageWord in $priorityWordsLines) {
    if (-not $usageWords.ContainsKey($usageWord.line.ToLower())) {
        $usageWords.Add($usageWord.line.ToLower(), ++$usageWordIndex)
    }
}
# Now do the same loop for naturally prioritized words
foreach ($usageWord in $usageWordsLines) {
    if (-not $usageWords.ContainsKey($usageWord.line.ToLower())) {
        if (-not $unprotectWords.ContainsKey($usageWord.line.ToLower())) {
            $usageWords.Add($usageWord.line.ToLower(), ++$usageWordIndex)
        } else {
            $usageWords.Add($usageWord.line.ToLower(), ($usageWordIndex + 50000))
        }
    }
}
Write-Host ("Loaded $usageWordIndex english words")
$usageWords
