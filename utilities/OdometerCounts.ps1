#$odometer1 = 'C:\Users\kevin\AppData\Roaming\Qwertigraph\odometerLifetime_20220115.ssv'
$odometer = 'C:\Users\s998010\AppData\Roaming\Qwertigraph\odometerLifetime.ssv'

$wordlines = Get-Content -Path $odometer
#$wordlines += Get-Content -Path $odometer2

$wins = 0
foreach ($wordline in $wordlines) {
    ($savings,$word,$qwerd,$chord,$form,$power,$saves,$matches,$chords,$misses,$other) = $wordline -split ';'
    try {
        if ($savings -notmatch '-') {
            $wins = $wins + ($savings) 
        }
    } catch {
        #Write-Error "Oops on $wordline giving $saves and $matches"
    }
}
"$wins characters"
"$($wins / 5) words"
"$($wins / (5 * 30)) minutes"
"$($wins / (5 * 30 * 60)) hours"