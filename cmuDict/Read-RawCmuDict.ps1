$cmuWordsFile = "$PsScriptRoot\cmudict-0.7b.txt"
# Uncomment this line to work with a small dictionary on problem words.
# $cmuWordsFile = "$PsScriptRoot\small_sample_cmudict-0.7b.txt"; $cmuWordsLines = $null; $usageWords = $null


$excludeWordsFile = "$PsScriptRoot\exclude_words.txt"
$excludeWordsLines = Get-Content -Path $excludeWordsFile
$excludeWords = @{} # Case insensitive hashtable
Foreach ($excludeWordsLine in $excludeWordsLines) {$excludeWords.Add($excludeWordsLine, $true)}

$cmuWordsFileObject = Get-ChildItem -Path $cmuWordsFile
if (($cmuWordsLines.count) -and ($cmuWordsFileObject.LastWriteTime -lt $cmuLastReadTime)) {
    # "Returning cached lines"
    Return $cmuWordsLines
}
# "Returning fresh lines"
$cmuLastReadTime = Get-Date 

$cmuWordsLines = Get-Content -Path $cmuWordsFile `
    | Select-String "^[A-Z']" `
    | Where-Object {$_ -notmatch "'"} `
    | Where-Object {$_ -notmatch "\("} `
    | Foreach-Object {$word, $pronunciation = $_ -split '  '; if (-not $excludeWords.ContainsKey($word)) {$_}}

$cmuWordsLines
