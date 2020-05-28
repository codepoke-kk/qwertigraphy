$cmuWordsFile = "$PsScriptRoot\cmudict-0.7b.txt"
#$cmuWordsFile = "$PsScriptRoot\small_sample_cmudict-0.7b.txt"

$cmuWordsFileObject = Get-ChildItem -Path $cmuWordsFile
if (($cmuWordsLines.count) -and ($cmuWordsFileObject.LastWriteTime -lt $cmuLastReadTime)) {
    # "Returning cached lines"
    Return $cmuWordsLines
}
# "Returning fresh lines"
$cmuLastReadTime = Get-Date 

$cmuWordsLines = Get-Content -Path $cmuWordsFile | Select-String "^[A-Z']" | Where-Object {$_ -notmatch "'"} | Where-Object {$_ -notmatch "\("}

$cmuWordsLines
