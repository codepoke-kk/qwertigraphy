$dictionaryFiles = @(
    "$PsScriptRoot\..\qwertigraph\dictionaries\anniversary_core.csv"
    "$PsScriptRoot\..\qwertigraph\dictionaries\anniversary_supplement.csv"
    "$PsScriptRoot\..\qwertigraph\dictionaries\anniversary_modern.csv"
    "$PsScriptRoot\..\qwertigraph\dictionaries\anniversary_phrases.csv"
    "$PsScriptRoot\..\qwertigraph\dictionaries\anniversary_cmu.csv"
)

$chordKeyers = @("c", "m", "v", "n", "x", "b")

function getNextChordKeyer {
    param ($chord)
    foreach ($chordKeyer in $chordKeyers) {
        if ($chord -notmatch $chordKeyer) {
            if ($chord.Length -gt 1) {
                $tempChord = alphaSort -chord "$chord$chordKeyer"
                $matchChord = $global:dictionaryEntries | Where-Object {$_.chord -eq $tempChord}
                if (-not $matchChord) {
                    return $chordKeyer
                } else {
                    Write-Host "Matched $tempChord"
                }
            } else {
                return $chordKeyer
            }
        }
    }
    return "z"
}

function alphaSort {
    param($chord) 
    $tempChord = $chord -split '' | Sort-Object
    return $tempChord -join ''

}

foreach ($dictionaryFile in $dictionaryFiles) {
    $global:dictionaryEntries = Import-CSV -Path $dictionaryFile
    foreach ($dictionaryEntry in $global:dictionaryEntries) {
        if ($dictionaryEntry.chord.Length -lt 3) {
            Do {
                $dictionaryEntry.chord += getNextChordKeyer -chord $dictionaryEntry.chord
                $dictionaryEntry.chord = alphaSort -chord $dictionaryEntry.chord
            } Until ($dictionaryEntry.chord.length -ge 3)
        }
    }
    $global:dictionaryEntries | Sort-Object {[int]($_.usage)} | Select-Object -Property @('word','form','qwerd','keyer','chord','usage') | Export-Csv -Path "$($dictionaryFile)" -NoTypeInformation

}

