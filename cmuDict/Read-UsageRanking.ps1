$usageWordsFile = "$PsScriptRoot\wiki-100k.txt"

$usageWordsFileObject = Get-ChildItem -Path $usageWordsFile
if (($usageWords.count) -and ($usageWordsFileObject.LastWriteTime -lt $usageLastReadTime)) {
    # "Returning cached lines"
    Return $usageWords
}
# "Returning fresh lines"
$usageLastReadTime = Get-Date
 
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
