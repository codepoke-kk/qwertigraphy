

"Began $(Get-Date)"

. $PSScriptRoot\Out-CmuCoaching.ps1

Out-CmuCoaching -source "$PSScriptRoot\..\scripts\cmu_dictionary.ahk" -destination "$PSScriptRoot\..\scripts\cmu_coaching.ahk" #-Verbose

"Ended $(Get-Date)"