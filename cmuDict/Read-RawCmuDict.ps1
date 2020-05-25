$cmuWordsFile = "$PsScriptRoot\cmudict-0.7b.txt"
# $cmuWordsFile = "$PsScriptRoot\small_sample_cmudict-0.7b.txt"

$cmuWordsLines = Get-Content -Path $cmuWordsFile | Select-String "^[A-Z']" | Where-Object {$_ -notmatch "'"} | Where-Object {$_ -notmatch "\("}

$cmuWordsLines
