$trainingWordsFile = "$PsScriptRoot\training_words.txt"

$trainingWordsLines = Get-Content -Path $trainingWordsFile | Select-String "^[a-zA-Z']" 
$trainingWords = @{}
foreach ($trainingWordsLine in $trainingWordsLines) {
    $trainingWord = $trainingWordsLine -split ' ', 2
    $trainingWords.Add($trainingWord[0].ToLower(), $trainingWord[1])
}
$trainingWords
