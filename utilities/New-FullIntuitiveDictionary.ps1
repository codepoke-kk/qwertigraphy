﻿$qwertigraph_root = "$(Split-Path -Parent -Path $PsScriptRoot)\qwertigraph"
$qwertigraph_appdata = "$($env:APPDATA)\Qwertigraph"
$dictionary_list_file = "$qwertigraph_appdata\dictionary_load.list"
# I need to not run this against every dictionary, but just against the two core dictionaries 
# $dictionary_lines = @(Get-Content -Path $dictionary_list_file)
$dictionary_lines = @('dictionaries\anniversary_supplement.csv','dictionaries\anniversary_core.csv')
$root_discovery_patterns_file = "$qwertigraph_root\classes\root_discovery_patterns.txt"
$root_discovery_patterns_lines = @(Get-Content -Path $root_discovery_patterns_file)
$uniform_patterns_file = "$qwertigraph_root\classes\uniform_patterns.txt"
$uniform_patterns_lines = @(Get-Content -Path $uniform_patterns_file)
$uniform_dictionary_path = "$qwertigraph_root\dictionaries\anniversary_uniform.csv"
$cmu_list = "$(Split-Path -Parent -Path $PsScriptRoot)\cmuDict\cmudict-0.7b.txt"
$exclude_list = "$(Split-Path -Parent -Path $PsScriptRoot)\cmuDict\exclude_words.txt"
$block_as_qwerds_file = "$qwertigraph_root\..\Utilities\block_as_qwerds.csv"
Write-Host "Uniform $uniform_dictionary_path"

# These are the canonical patterns that will build the uniform qwerds from looking at the words and forms of each entry
Write-Host "Loading uniform qwerd patterns"
$uniform_patterns = New-Object System.Collections.ArrayList
$comment = ''
foreach ($uniform_patterns_line in $uniform_patterns_lines) {
    if (($uniform_patterns_line -notmatch '^;') -and ($uniform_patterns_line -match ',.*,')) {
        $values = $uniform_patterns_line -split ','
        $uniform_pattern = New-Object PsCustomObject -Property @{'word_pattern' = $values[0]; 'form_pattern' = $values[1]; 'replacement_pattern' = $values[2]; 'comment' = $comment}
        $uniform_patterns.Add($uniform_pattern) | Out-Null
        # Write-Host ("Data: $uniform_pattern")
    } else {
        # Write-Host ("Comment: $uniform_patterns_line")
        $comment = $uniform_patterns_line
    }
}

# These patterns will extract a root from from any word/form pair 
# The "usage" score of each entry will be based on the root form, not the specific conjugation of the word 
Write-Host "Loading root discovery patterns"
$global:root_discovery_patterns = New-Object System.Collections.ArrayList
$comment = ''
foreach ($root_discovery_patterns_line in $root_discovery_patterns_lines) {
    if (($root_discovery_patterns_line -notmatch '^;') -and ($root_discovery_patterns_line -match ',.*,')) {
        $values = $root_discovery_patterns_line -split ','
        $root_discovery_pattern = New-Object PsCustomObject -Property @{'word_pattern' = $values[0]; 'form_pattern' = $values[1]; 'replacement_pattern' = $values[2]; 'comment' = $comment}
        $root_discovery_patterns.Add($root_discovery_pattern) | Out-Null
        # Write-Host ("Data: $root_discovery_pattern")
    } else {
        # Write-Host ("Comment: $root_discovery_patterns_line")
        $comment = $root_discovery_patterns_line
    }
}
# This function will return the root form of any word/form pair 
function Get-RootDiscoveryPattern {
    param (
        $word,
        $form
    )
    # Write-Host "Getting root discovery pattern from $word and $form"
    foreach ($root_discovery_pattern in $global:root_discovery_patterns) {
        if (($word -match $root_discovery_pattern.word_pattern) -and ($form -match $root_discovery_pattern.form_pattern)) {
            $form = $form -replace $root_discovery_pattern.form_pattern, $root_discovery_pattern.replacement_pattern
        }
    }
    # Write-Host "Returning root discovery pattern of $form"
    return $form 
}

### Load the odometer
# This is a count of every time a word was used in the last year or so
# It gives a usage number, and the usage number determines between any two words which is saddled with a disambiguator
Write-Host "Loading odometer"
$odometer_file = "$qwertigraph_appdata\odometerLifetime.ssv"
$odometer_lines = Get-Content -Path $odometer_file
$odometer = @{}
foreach ($odometer_line in $odometer_lines) {
    ($savings,$word,$qwerd,$chord,$form,$power,$saves,$matches,$chords,$misses,$other) = $odometer_line -split ';'
    try {
        $form = Get-RootDiscoveryPattern -word $word -form $form 
        if (-not $odometer.ContainsKey($form)) {
            $odometer[$form] = 0
        }
        $odometer[$form] += [convert]::ToInt32($savings) 
    } catch {
        # Write-Host ("Failed with $savings for $odometer_line")
    }
}

Write-Host "Loading exclude words"
### Load the exclude words 
# No qwerd allowed to match a word in this list 
# "AM" is a great qwerd, but it's a real word, so it must be excluded 
$block_as_qwerds = @{} # Case insensitive hashtable of words to exclude as qwerds
Get-Content -Path $block_as_qwerds_file `
    | Foreach-Object {$block_as_qwerds[$_] = $true}
# This list was used to build the list of $block_as_qwerds
# I don't think I need this any more, but I'm keeping it for later reference 
$exclude_words = @{} # Case insensitive hashtable of words to exclude from the CMU List
Get-Content -Path $exclude_list `
    | Foreach-Object {$exclude_words[$_] = $true}
$cmu_words = @{}
Get-Content -Path $cmu_list `
    | Select-String "^[A-Z']" `
    | Where-Object {$_ -notmatch "'"} `
    | Where-Object {$_ -notmatch "\("} `
    | Foreach-Object {$word, $pronunciation = $_ -split '  '; if (-not $exclude_words.ContainsKey($word)) {$cmu_words[$word] = $pronunciation}}



### Load the dictionary 
# I'm building some tracking data into this list that is not used nor retained outside this script 
# I manually inspect a lot of this data after the fact and before a save to make sure I'm building things that make sense
Write-Host "Loading dictionaries"
$dictionary = @{}
foreach ($dictionary_line in $dictionary_lines) {
    $dictionary_path = "$qwertigraph_root\$dictionary_line" -ireplace '^.*AppData', "$($env:APPDATA)\qwertigraph"
    Write-Host ("$dictionary_path")
    $dictionary_rows= Import-Csv -Path $dictionary_path | Where-Object {$_.qwerd -notmatch '\d'} | Where-Object {$_.word -notmatch '\#name\?'}
    foreach ($dictionary_row in $dictionary_rows) {
        # Find the root form to get a consistent usage across conjugations of a word 
        $odometer_form = Get-RootDiscoveryPattern -word $dictionary_row.word -form $dictionary_row.form
        $dictionary_item = New-Object PsCustomObject -Property @{
            'word' = $dictionary_row.word
            'form' = $dictionary_row.form
            'qwerd' = $dictionary_row.qwerd
            'keyer' = $dictionary_row.keyer
            'chord' = $dictionary_row.chord
            'usage' = if ($odometer.ContainsKey($odometer_form)) {$odometer[$odometer_form]} else {0}
            'conflict' = ''
            'old_qwerd' = $dictionary_row.qwerd
            'qwerd_length_delta' = 0
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
# $dictionary.values | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage') | Sort-Object -Property 'usage' | Out-GridView

# I use this just to make sure I sort the keyers in the Out-GridView stuff during the review step
$keyer_sort = @('o', 'i', 'u')
# Sometimes a dozen words have the same form and come down to the same qwerd
# I disambiguate them in the order shown below
# 8th disambiguator would be i2 because 8 is the halfway through the 3rd looping of the keyers
$uniform_keyers = @('o', 'i', 'u')
$uniform_counters = @( '', '1', '2', '3', '4', '5', '6', '7', '8', '9')

Write-Host "Creating uniform qwerds"
# Loop across all existing dictionary entries and create a new qwerd for each
$uniform_entries = @{}
$deltas = New-Object System.Collections.ArrayList
$cmu_matches = New-Object System.Collections.ArrayList
# This is a debugging tool - If an entry's word matches this pattern, I will give debugging output on that word 
$trace_pattern = 'no trace word'
# Sort descending by usage so more used words are created first
# Make sure we only disambiguate the lesser used words 
foreach ($dictionary_entry in ($dictionary.values | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage', 'dictionary_name') | Sort-Object -Descending -Property @{Expression={$_.usage};Descending=$true}, @{Expression={$_.word.length};Descending=$false})) {
    # The qwerd starts as the form, and it will be transformed by the uniform pattern rules into it's ideal form 
    # After the ideal from is reached, it will be reviewed for whether it needs to be disambiguated
    $qwerd = $dictionary_entry.form 
    # The comment is not retained, but it's visible in the output from this script so I can review the rules applied to the form in creating the qwerd
    $comment = ''
    foreach ($uniform_pattern in $uniform_patterns) {
        # Debug output if trace_pattern matches 
        if ($dictionary_entry.word -match $trace_pattern) {Write-Host ("Evaluating $qwerd against $uniform_pattern")}
        # A uniform rule applies if the word and form both matches their patterns 
        if (($qwerd -match $uniform_pattern.form_pattern) -and ($dictionary_entry.word -match $uniform_pattern.word_pattern)) {
            # Debug output if trace_pattern matches 
            if ($dictionary_entry.word -match $trace_pattern) {Write-Host ("Matched because $($uniform_pattern.comment)")}
            $qwerd = $qwerd -replace $uniform_pattern.form_pattern, $uniform_pattern.replacement_pattern 
            $comment = "$comment$($uniform_pattern.comment)"
        } else {
            if ($dictionary_entry.word -match $trace_pattern) {
                # Uncomment for more massive debugging data 
                # Write-Host ("Qwerd match of $qwerd against $($uniform_pattern.form_pattern) is $($qwerd -match $uniform_pattern.form_pattern)")
                # Write-Host ("Word match of $($dictionary_entry.word) against $($uniform_pattern.word_pattern) is $($dictionary_entry.word -match $uniform_pattern.word_pattern)")
            }
        }
    }
    # All qwerds are stored in ProperCase and transformed to lower and upper on the fly in dictionary load 
    $qwerd = (Get-Culture).TextInfo.ToTitleCase($qwerd)
    # Debug output if trace pattern is set 
    if ($dictionary_entry.word -match $trace_pattern) {Write-Host ("Transformed $($dictionary_entry.word)/$($dictionary_entry.usage) as $($dictionary_entry.form) to $qwerd from '$($dictionary_entry.dictionary_name)'")}
    # Create the new entry with the new qwerd, forcing Title casing
    # Tracking changed and comment and conflicts for review before saving  
    $new_entry = New-Object PsCustomObject -Property @{
        'word' = $dictionary_entry.word
        'form' = $dictionary_entry.form
        'old_qwerd' = $dictionary_entry.qwerd
        'qwerd' = $qwerd
        'qwerd_length_delta' = $qwerd.length - $dictionary_entry.qwerd.length 
        'keyer' = ''
        'chord' = "q$((($qwerd.toLower() -split '') | Sort-Object -Unique) -join '')"
        'usage' = $dictionary_entry.usage
        'dictionary_path' = $uniform_dictionary_path
        'dictionary_name' = $dictionary_entry.dictionary_name 
        'conflicted' = 0
        'conflict' = if (($dictionary.ContainsKey($qwerd) -and ($dictionary[$qwerd].word -ne $dictionary_entry.word))) {
            $dictionary[$qwerd].word
        } else {
            ''
        }
        'changed' = 0
        'change' = if ($dictionary_entry.qwerd.toLower() -ne $qwerd) {
            $dictionary_entry.qwerd.toLower()
        } else {
            ''
        }
        'comment' = $comment 
    }
    $new_entry.conflicted = ($new_entry.conflict.length -gt 0)
    $new_entry.changed = ($new_entry.change.length -gt 0)

    # Apply a disambiguator (keyer) if this qwerd is already in use 
    $newentry_keyer = ''
    if (($uniform_entries.ContainsKey("$($new_entry.qwerd)")) -or ($block_as_qwerds.ContainsKey($new_entry.qwerd))) {
        :CounterLoop foreach ($counter in $uniform_counters) {
            :KeyerLoop foreach ($keyer in $uniform_keyers) {
                $newentry_keyer = "$keyer$counter"
                if ((-not $uniform_entries.ContainsKey("$($new_entry.qwerd)$newentry_keyer")) -and (-not $block_as_qwerds.ContainsKey($new_entry.qwerd))) {Break CounterLoop}
            }
        }
    }
    $new_entry.keyer = $newentry_keyer
    $qwerd = "$($new_entry.qwerd)$newentry_keyer"
    $new_entry.qwerd = $qwerd
    $new_entry.qwerd_length_delta = $qwerd.length - $new_entry.old_qwerd.length 

    # check to see whether the qwerd is a word 
    # Tracking to see how often we use real words as qwerds for later review and addition to block as qwerds
    # I allow some real words to be hijacked by my process, but some are just too highly used 
    if($cmu_words.ContainsKey($qwerd)) {$cmu_matches.Add($new_entry) | Out-Null}

    # Finally add this new entry to the new dictionary 
    $uniform_entries[$qwerd] = $new_entry
    # Do we have a conflict? or a change?
    # Track and output changes for review 
    if ($new_entry.conflict -or $new_entry.change) {
        $delta = New-Object PsCustomObject -Property @{'word' = $new_entry.word; 'qwerd' = $new_entry.qwerd; 'old_qwerd' = $new_entry.old_qwerd; 'qwerd_length_delta' = $new_entry.qwerd_length_delta; 'conflict' = $new_entry.conflict; 'conflicted' = $new_entry.conflicted; 'change' = $new_entry.change; 'changed' = $new_entry.changed; 'usage' = $new_entry.usage; 'dictionary_name' = $new_entry.dictionary_name; 'comment' = $new_entry.comment}
        $deltas.Add($delta) | Out-Null
    }
}


Write-Host "Presenting data"
$deltas | Sort-Object -Property 'word' | Select-Object @('word', 'qwerd', 'old_qwerd', 'qwerd_length_delta', 'conflict', 'change', 'conflicted', 'changed', 'usage', 'dictionary_name', 'comment') | Out-GridView -title "$($deltas.count) Deltas"
$cmu_matches | Sort-Object -Property 'word' | Select-Object @('word', 'qwerd', 'old_qwerd', 'conflict', 'change', 'conflicted', 'changed', 'usage', 'dictionary_name', 'comment') | Out-GridView -title "$($cmu_matches.count) CMU Matches"
$cmu_matches | Sort-Object -Property 'qwerd' | Select-Object @('qwerd') | Export-CSV -Force -NoTypeInformation -Path "$PsScriptRoot\block_words.csv"

# Set the whatif here, and honor it throughout 
$whatif = $true
if ($whatif) {
    Write-Host ("$($uniform_entries.count) entries would be written into $uniform_dictionary_path")
    $uniform_entries.values | Sort-Object {$keyer_sort.IndexOf($_.keyer)} | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage', 'dictionary_name') | Out-GridView -title "$($uniform_entries.count) to define $(Split-Path -Leaf $uniform_dictionary_path).csv"
} else {
    $uniform_entries.values | Sort-Object {$keyer_sort.IndexOf($_.keyer)} | Select-Object @('word', 'form', 'qwerd', 'keyer', 'chord', 'usage') | Export-CSV -Force -NoTypeInformation -Path $uniform_dictionary_path
    Write-Host ("$($uniform_entries.count) entries written into $uniform_dictionary_path")
}
