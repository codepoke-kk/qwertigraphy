$usageWordsFile = "$PsScriptRoot\wiki-100k.txt"

$usageWordsLines = Get-Content -Path $usageWordsFile | Select-String "^[^#]" 
$usageWords = @{}
$usageWordIndex = 0
foreach ($usageWord in $usageWordsLines) {
    if (-not $usageWords.ContainsKey($usageWord.line.ToLower())) {
        $usageWords.Add($usageWord.line.ToLower(), ++$usageWordIndex)
    }
}
Write-Verbose ("Loaded $usageWordsIndex words")
$usageWords
