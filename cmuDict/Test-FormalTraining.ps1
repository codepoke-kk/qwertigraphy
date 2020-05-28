"Began $(Get-Date)"


$trainingWords = . $PSScriptRoot\Read-TrainingWords.ps1
"Loaded $($trainingWords.get_count()) training words"
$rawCmuWordsLines = . $PSScriptRoot\Read-RawCmuDict.ps1
"Loaded $($rawCmuWordsLines.get_count()) raw CMU words"

$filteringCount = 0
if (-not $filteringHash) {
    $filteringHash = @{}
    $rawCmuWordsLines | ForEach-Object {
            $filteringCount++
            Write-Progress -Id 1 -Activity "$filteringCount/$($rawCmuWordsLines.count)"
            $word, $pronunciation = $_ -split '  '
            if(-not $filteringHash.ContainsKey($word.ToLower())) {$filteringHash.Add($word.ToLower(), $pronunciation)}
        }
}

. $PSScriptRoot\Add-FormalOutline.ps1

$testCounter = 0
$failureCounter = 0
$focusWord = ''
Foreach ($trainingWord in $trainingWords.Keys) {
    if(($focusWord) -and ($trainingWord -ne $focusWord)) {Continue}
    ++$testCounter
    
    $formal = ConvertTo-FormalGreggOutline -word $trainingWord -pronunciation $filteringHash.$trainingWord
    $passed = ($formal -ceq $trainingWords[$trainingWord])
    # "$word = $formal $passed"
    if (-not $passed) {
        "`$pronunciation = `$pronunciation -creplace '$($filteringHash.$trainingWord) ?\b', '$($trainingWords[$trainingWord])'`t#$trainingWord is not $formal"
        $failureCounter++
    }
    Write-Progress -Id 1 -Activity "$testCounter/$($trainingWords.Keys.count) $trainingWord, $filteringHash.$trainingWord, $formal, $trainingWord" -PercentComplete (100*$testCounter/$trainingWords.Keys.Count)
}


"Ended $(Get-Date) with $failureCounter failures"