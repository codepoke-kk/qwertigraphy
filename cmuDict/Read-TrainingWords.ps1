$trainingWordsFile = "$PsScriptRoot\training_words.txt"

$trainingWordsFileObject = Get-ChildItem -Path $trainingWordsFile
if (($trainingWords.count) -and ($trainingWordsFileObject.LastWriteTime -lt $trainingLastReadTime)) {
    # "Returning cached lines"
    Return $trainingWords
}
# "Returning fresh lines"
$trainingLastReadTime = Get-Date 

$trainingWordsLines = Get-Content -Path $trainingWordsFile | Select-String "^[a-zA-Z']" 
$trainingWords = @{}
foreach ($trainingWordsLine in $trainingWordsLines) {
    $trainingWord = $trainingWordsLine -split ' ', 2
    $trainingWords.Add($trainingWord[0].ToLower(), $trainingWord[1])
}
$trainingWords
