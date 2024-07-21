$qwertigraph_root = "$(Split-Path -Parent -Path $PsScriptRoot)\qwertigraph"
$qwertigraph_appdata = "$($env:APPDATA)\Qwertigraph"
$dictionary_lines_file = "$qwertigraph_appdata\dictionary_load.list"
$dictionary_lines = @(Get-Content -Path $dictionary_list_file)
$uniform_dictionary_path = "$qwertigraph_root\dictionaries\anniversary_uniform.csv"
Write-Host "Uniform $uniform_dictionary_path"

$dictionary = @{}

foreach ($dictionary_line in $dictionary_lines) {
    $dictionary_path = "$qwertigraph_root\$dictionary_line" -ireplace '^.*AppData', "$($env:APPDATA)\qwertigraph"
    $dictionary_rows= Import-Csv -Path $dictionary_path
    foreach ($dictionary_row in $dictionary_rows) {
        $dictionary_item = New-Object PsCustomObject -Property @{
            'word' = $dictionary_row.word
            'form' = $dictionary_row.form
            'qwerd' = $dictionary_row.qwerd
            'keyer' = $dictionary_row.keyer
            'chord' = $dictionary_row.chord
            'usage' = $dictionary_row.usage
            'conflict' = ''
            'old_qwerd' = $dictionary_row.qwerd
            'banner' = ''
            'dictionary_path' = $dictionary_path
            'dictionary_name' = Split-Path -Leaf $dictionary_path
        }
        # Write-Host ("row $($dictionary_item)")
        if (-not $dictionary.ContainsKey($dictionary_item.qwerd)){
            $dictionary[$dictionary_item.qwerd] = $dictionary_item
        }
    } 
}
Write-Host ("Dictionary contains $($dictionary.keys.count) entries")

$keyer_sort = @('o', 'u', 'i', 'a', 'e', 'w', 'y')
$uniform_keyers = @('u', 'i', 'w', 'q', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'j', 'k', 'l')

function getNewRows() {
    param (
        $qwerd_pattern,
        $form_pattern,
        $word_pattern,
        $newqwerd_pattern
    )
    
    $new_rows = New-Object System.Collections.ArrayList

    $banner = "$($qwerd_pattern.toUpper()) to $($newqwerd_pattern.toUpper())"

    # Get rows that match the source pattern 
    $rows = $dictionary.values | Where-Object {$_.qwerd -match $qwerd_pattern -and $_.form -match $form_pattern -and $_.word -match $word_pattern}

    # Sift out rows from the CMU and display them so they can be fixed. I want to return no rows until the CMU is right 
    $cmupurge_rows = $rows | Where-Object {$_.form -notmatch '-'}

    # If we have CMU rows, then just pop that up 
    if ($cmupurge_rows.count) {
        $cmupurge_rows | Out-GridView -title "PURGE: $($cmupurge_rows.count) $banner to purge from CMU"
        Throw "CMU entries must be deleted or corrected before proceeding"
    } else {
        # I am going to want to add rows in reverse keyer order null, then o, then i, etc 
        foreach ($row in ($rows | Sort-Object {$keyer_sort.IndexOf($_.keyer)})) {
            # Create the new row with the new qwerd, keeping the Title casing if present 
            $new_row = New-Object PsCustomObject -Property @{
                'word' = $row.word
                'form' = $row.form
                'old_qwerd' = $row.qwerd
                'qwerd' = (Get-Culture).TextInfo.ToTitleCase(($row.qwerd -ireplace $qwerd_pattern, $newqwerd_pattern -ireplace "$($row.keyer)$", ""))
                'keyer' = $row.keyer
                'chord' = "q$((($row.qwerd.toLower() -split '') | Sort-Object -Unique) -join '')"
                'usage' = $row.usage
                'banner' = $banner
                'dictionary_path' = $uniform_dictionary_path
                'dictionary_name' = Split-Path -Leaf $uniform_dictionary_path
                'conflict' = ''
            }
            # Don't conflict with with existing words, but also ignore conflicts when the words and qwerds are the same 
            if (($dictionary.ContainsKey($new_row.qwerd) -and $dictionary[$new_row.qwerd].word -ne $new_row.word) `
                -or ($new_rows | Where-Object {$_.qwerd -eq $new_row.qwerd})) {
                $new_row.conflict = $dictionary[$new_row.qwerd].word
                :ChooseKeyer foreach ($intuitive_keyer in $uniform_keyers) {
                    if ((-not $dictionary.ContainsKey("$($new_row.qwerd)$intuitive_keyer")) -and (-not ($new_rows | Where-Object {$_.qwerd -eq "$($new_row.qwerd)$intuitive_keyer"}))) {
                        $new_row.qwerd += $intuitive_keyer
                        $new_row.keyer = $intuitive_keyer
                        # $dictionary[$new_row.qwerd] = $new_row
                        break ChooseKeyer
                    }
                }
            }
            $new_rows.Add($new_row) | Out-Null
        }
        return $new_rows
    }
}

$uniform_patterns = New-Object System.Collections.ArrayList
$uniform_patterns.Add((New-Object PsCustomObject -Property @{'qwerd_pattern' = '^RE'; 'form_pattern' = '^R-E'; 'word_pattern' = 'RE'; 'newqwerd_pattern' = 'r'})) | Out-Null
$uniform_patterns.Add((New-Object PsCustomObject -Property @{'qwerd_pattern' = 'MN'; 'form_pattern' = 'MN'; 'word_pattern' = '.'; 'newqwerd_pattern' = 'mm'})) | Out-Null
$uniform_patterns.Add((New-Object PsCustomObject -Property @{'qwerd_pattern' = 'TD'; 'form_pattern' = 'TD'; 'word_pattern' = '.'; 'newqwerd_pattern' = 'dd'})) | Out-Null

# Set the whatif here, and honor it throughout 
$iteration = 0
foreach ($up in $uniform_patterns.toArray()) {
    Write-Host "Working Uniform Pattern $($up.qwerd_pattern) to $($up.newqwerd_pattern)"
    $add_rows = getNewRows -qwerd_pattern $up.qwerd_pattern -form_pattern $up.form_pattern -word_pattern $up.word_pattern -newqwerd_pattern $up.newqwerd_pattern 
    foreach ($add_row in $add_rows) {
        $iteration++
        if (($dictionary.ContainsKey($add_row.qwerd)) -and ($dictionary[$add_row.qwerd].word -ne $add_row.word)) {Throw "On iteration $iteration, received a conflict row to add, $($add_row)"}
        $dictionary[$add_row.qwerd] = $add_row
    }
}

$uniform_entries = $dictionary.values | Where-Object {$_.dictionary_path -eq $uniform_dictionary_path}

$whatif = $false
if ($whatif) {
    Write-Host ("$($uniform_entries.count) entries would be written into $uniform_dictionary_path")
    $uniform_entries | Sort-Object {$keyer_sort.IndexOf($_.keyer)} | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage', 'conflict', 'banner', 'dictionary_name') | Out-GridView -title "$($uniform_entries.count) to define $(Split-Path -Leaf $uniform_dictionary_path).csv"
} else {
    $uniform_entries | Sort-Object {$keyer_sort.IndexOf($_.keyer)} | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage') | Export-CSV -Force -NoTypeInformation -Path $uniform_dictionary_path
    Write-Host ("$($uniform_entries.count) entries written into $uniform_dictionary_path")
}
