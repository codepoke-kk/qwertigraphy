$dictionaryFile = "$PsScriptRoot\anniversary_trainer.txt"
$dictionaryFile = "$PsScriptRoot\anniversary_raw.txt"
$dictionaryFileObject = Get-ChildItem -Path $dictionaryFile
#if (($dictionaryLines.count) -and ($dictionaryFileObject.LastWriteTime -lt $dictionaryLastReadTime)) {
#    # "Returning cached lines"
#    Return $dictionaryLines
#}
# "Returning fresh lines"
$dictionaryLastReadTime = Get-Date 

$dictionaryLines = Get-Content -Path $dictionaryFile

$dictionaryLines
