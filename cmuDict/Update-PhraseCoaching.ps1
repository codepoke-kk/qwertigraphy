

"Began $(Get-Date)"

. $PSScriptRoot\Out-PhraseCoaching.ps1

Out-PhraseCoaching -source "$PSScriptRoot\..\scripts\phrases.ahk" -destination "$PSScriptRoot\..\scripts\phrase_coaching.ahk" -Verbose

"Ended $(Get-Date)"