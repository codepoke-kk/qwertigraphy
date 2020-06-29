$usageWordsFile = "$PsScriptRoot\wiki-100k.txt"
$priorityWordsFile = "$PsScriptRoot\priority_words.txt"
$priorityWordsLines = Get-Content -Path $priorityWordsFile | Select-String "^[^#]" 

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
# Loop across the priority words first and add them first so they have higher priority
foreach ($usageWord in $priorityWordsLines) {
    if (-not $usageWords.ContainsKey($usageWord.line.ToLower())) {
        $usageWords.Add($usageWord.line.ToLower(), ++$usageWordIndex)
    }
}
# Now do the same loop for naturally prioritized words
foreach ($usageWord in $usageWordsLines) {
    if ((-not $usageWords.ContainsKey($usageWord.line.ToLower())) -and (-not $excludeWords.ContainsKey($usageWord.line.ToLower()))) {
        $usageWords.Add($usageWord.line.ToLower(), ++$usageWordIndex)
    }
}
Write-Verbose ("Loaded $usageWordsIndex words")
$usageWords
