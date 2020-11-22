### Load all the raw data we'll need to build the final dictionary and coaching file
# Read the Carnegie Mellon University pronunciation dictionary
$rawDictionaryLines = . $PSScriptRoot\Read-RawAnniversary.ps1
"Loaded $($rawDictionaryLines.get_count()) raw Gregg words"

$lineCount = 0

$notes = @{} # Case insensitive hashtable
Function Convert-RawToFormal {
    param (
        $rawForm
    )
    ($givenForm, $note) = $rawForm -split ' ', 2
    if ($note) {
        # Examine notes with: $notes.GetEnumerator() | Sort {[int]$_.value}
        # Create switch statement with: $notes.GetEnumerator() | Sort -Descending {[int]$_.value} | % {"`t`t`t'$($_.key)' {}"}
        if (-not $notes.ContainsKey($note)) {
            $notes[$note] = 1
        } else {
            $notes[$note]++
        }
    }

    # Give hyphens to disjoins, erase leading and trailing hyphens, raise all h's, and lower all 'ing' h's
    $givenForm = $givenForm -replace '/', '-/-' -replace '^-', '' -replace '-$', '' -replace '\bh-', '^-h-\-' -replace '-h$', '-\-h'
    $outForm = Switch -Exact ($note) {
		'(e2)' {return $givenForm -replace 'e', 'e2'}
		'(s1)' {return $givenForm}
		'(s2)' {return $givenForm -replace 's', 's2'}
		'(a2)' {return $givenForm -replace 'a', 'a2'}
		'(th2)' {return $givenForm -replace 'th', 'th2'}
		'(intersected)' {return $givenForm -replace '/', '<'}
		'(e1, e2)' {return $givenForm -replace 'e([^e]*)e', 'e$1e2'}
		'(raised)' {return $givenForm -replace '^', '^-'}
		'(ye2)' {return $givenForm -replace 'ye', 'ye2'}
		'(s2-e2)' {return $givenForm -replace 's([^e]*)e', 's2$1e2'}
		'(th1)' {return $givenForm}
		'(o on side)' {return $givenForm -replace 'o', 'o2'}
		'(i2)' {return $givenForm -replace 'i', 'i2'}
		'(e1)' {return $givenForm}
		'(s1, s2)' {return $givenForm -replace 's([^s]*)s', 's$1s2'}
		'(i1)' {return $givenForm}
		'(angle between k and p)' {return $givenForm -replace 'k-p', 'kp'}
		'(e2, e1)' {return $givenForm -replace 'e([^e]*)e', 'e2$1e'}
		'(o sideways)' {return $givenForm -replace 'o', 'o2'}
		'(angled join between n and u)' {return $givenForm -replace 'n-u', 'nu'}
		'(a2, e2)' {return $givenForm -replace 'a([^e]*)e', 'a2$1e2'}
		'(s2, s1)' {return $givenForm -replace 's([^s]*)s', 's2$1s'}
		'(angle between n and u)' {return $givenForm -replace 'n-u', 'nu'}
		'(s2-s1)' {return $givenForm -replace 'ss', 's2s'}
		'(ya2)' {return $givenForm -replace 'ya', 'ya2'}
		'(over last character)' {return $givenForm -replace '/-', '^-'}
		'(smooth join between s and r)' {return $givenForm -replace 's-r', 'sr'}
		'(angle between e and s)' {return $givenForm -replace 'e-s', 'es'}
		'(e2, e2)' {return $givenForm -replace 'e', 'e2'}
		'(upright o)' {return $givenForm -replace 'o', 'o1'}
		'(angle between u and s)' {return $givenForm -replace 'u-s', 'us'}
		'(angle between n and u, e2)' {return $givenForm -replace 'n-u', 'nu' -replace 'e', 'e2'}
		'(th1-e2)' {return $givenForm -replace 'th-e', 'th-e2'}
		'(at end of th)' {return $givenForm -replace 'th-', 'th-^->-'}
		'(a2, a2)' {return $givenForm -replace 'a', 'a2'}
		'(real estate)' {return $givenForm}
		'(connected at top of loop)' {return $givenForm -replace 'd-ya', 'dya'}
		'(no angle between o and t)' {return $givenForm -replace 'o-t', 'ot'}
		'(s1-th1)' {return $givenForm}
		'(angle between th and u)' {return $givenForm -replace 'th-u', 'thu'}
		'(a2, a1)' {return $givenForm -replace 'a([^a]*)a', 'a2$1a'}
		'(th2, th1)' {return $givenForm -replace 'th([^th]*)th', 'th2$1th'}
		'(sideways, raised)' {return $givenForm -replace 'o', '^-o2'}
		'(s2, raised)' {return $givenForm -replace 's', '^-s2'}
		'(angle between o and t)' {return $givenForm}
		'(intersected, e1)' {return $givenForm -replace '/', '<'}
		'(angle between u and v)' {return $givenForm -replace 'u-v', 'uv'}
		'(small i)' {return $givenForm -replace 'i', 'i3'}
		'(above line)' {return $givenForm -replace '^', '^-'}
		'(s1-s2)' {return $givenForm -replace 'ss', 'ss2'}
		'(angle between a and s)' {return $givenForm -replace 'a-s', 'as'}
		'(s1-s1)' {return $givenForm -replace 'ss', 's-s'}
		'(ea2)' {return $givenForm -replace 'ea', 'ea2'}
		'(s2, th1)' {return $givenForm -replace 's', 's2'}
		'(o long)' {return $givenForm}
		'(th2, s2)' {return $givenForm -replace 'th', 'th2' -replace 's', 's2'}
		'(l above e)' {return $givenForm -replace 'e-l', 'el2'}
		'o-p-r-a-sh' {return $givenForm -replace ' o-p-r-a-sh', '-/-o-p-r-a-sh'}
		'(s2-s2, raised)' {return $givenForm -replace '^.*$', '^-s2-s2'}
		'(angle between mn and u)' {return $givenForm -replace 'mn-u', 'mnu'}
		'(dot in front of i)' {return $givenForm -replace '\^-h', 'h-/'}
		'(e1, e1, e2)' {return $givenForm -replace 'e$', 'e2'}
		'(k on line)' {return $givenForm}
		'(e above)' {return $givenForm -replace 'e$', '^-e'}
		'(a1-s1 to left of a)' {return $givenForm -replace 'a-s', 'as2'}
		'(sideways)' {return $givenForm -replace 'o', 'o2'}
		'(r-df blended)' {return $givenForm -replace 'r-df', 'rdf'}
		'(angle between sh and s)' {return $givenForm -replace 'sh-s', 'shs'}
		'(e2, angle between e and s)' {return $givenForm -replace 'e-s', 'e2s'}
		'(angled join)' {return $givenForm -replace 'n-u', 'nu'}
		'(s1, s1)' {return $givenForm}
		'(s raised)' {return $givenForm -replace 's', '^-s'}
		'(angle between o and th2)' {return $givenForm -replace 'o-th', 'oth2'}
		'(e1 above n)' {return $givenForm}
		'(th1, s2, s at end of th)' {return $givenForm}
		'(a1)' {return $givenForm}
		'(dot in front of a)' {return $givenForm -replace '\^-h', 'h-/'}
		'(th1, s2, s below end of th)' {return $givenForm -replace '/', '\'}
		'(v-r blended)' {return $givenForm -replace 'v-r', 'vr'}
		'(raised d-s)' {return $givenForm -replace 'd-s', '^-d-s'}
		'(th2-e2, e1, e2)' {return $givenForm -replace 'th-e', 'th2-e2' -replace 'e$', 'e2'}
		'(s2, angle between s and o)' {return $givenForm -replace 's-o', 's2o'}
		'(angle between o and m)' {return $givenForm -replace 'o-m', 'om'}
		'(angle between u and s, e2)' {return $givenForm -replace 'u-s', 'us' -replace 'e', 'e2'}
		'(e1, no angle between e, s, and o)' {return $givenForm -replace 'e-s-o', 'eso'}
		'(reversed a)' {return $givenForm -replace 'a', 'a2'}
		'(s2 raised)' {return $givenForm -replace 's', '^-s2'}
		'(k raised)' {return $givenForm -replace 'k', '^-k'}
		'(t-f blended)' {return $givenForm -replace 't-f', 'tf'}
		'(p-e2)' {return $givenForm -replace 'p-e', 'p-e2'}
		'(u blended with ng)' {return $givenForm -replace 'u-ng', 'ung'}
		'(yi2)' {return $givenForm -replace 'yi', 'yi2'}
		'(e1, e1)' {return $givenForm}
		'(th2-s2)' {return $givenForm -replace 'th-s', 'th2-s2'}
		'(j and r intersected)' {return $givenForm -replace '/', '<'}
		'(s1, angle between u and s)' {return $givenForm -replace 'u-s', 'us'}
		'(e2, s1)' {return $givenForm -replace 'e', 'e2'}
		'(angle between tm and u)' {return $givenForm -replace 'tm-u', 'tmu'}
		'(a2, ya2)' {return $givenForm -replace 'a', 'a2'}
		'(m and p intersected)' {return $givenForm -replace '/', '<'}
		'(dash below o)' {return $givenForm}
		'(th2-e2)' {return $givenForm -replace 'th-e', 'th2-e2'}
		'(raised p)' {return $givenForm -replace 'p', '^-p'}
		'(raised, joined at top)' {return $givenForm -replace 'ya-b', '^-yab'}
		'(o-r below x)' {return $givenForm -replace 'o-r', '\-o-r'}
		'(e2-th1)' {return $givenForm -replace 'e', 'e2'}
		'(n on line)' {return $givenForm}
		'(s2-a2)' {return $givenForm -replace 's-a', 's2-a2'}
		'(angle between r and u)' {return $givenForm -replace 'r-u', 'ru'}
		'(e2, e2-e2)' {return $givenForm -replace 'e', 'e2'}
		'(a2, o sideways)' {return $givenForm -replace 'a', 'a2' -replace 'o', 'o2'}
		'(no angle between o and m)' {return $givenForm -replace 'o-m', 'om'}
		'(n above line)' {return $givenForm -replace 'n', '^-n'}
		'(upright u)' {return $givenForm}
		'(angle between p and o)' {return $givenForm -replace 'p-o', 'po'}
		'(angle between v and l)' {return $givenForm -replace 'v-l', 'vl'}
		'(on side)' {return $givenForm -replace 'o', 'o2'}
		'(s2, s1, s2)' {return $givenForm -replace '^s', 's2' -replace 's$', 's2'}
		'(a2, a2, a2)' {return $givenForm -replace 'a', 'a2'}
		'(s1-th2)' {return $givenForm -replace 'th', 'th2'}
        Default {return $givenForm}
    }
}
Function Get-Words {
    param (
        $rawWords
    )
    $rawWords = $rawWords -replace '\(.+\)', '' -replace ';[^,]+', '' -replace '^ +', '' -replace ' +$', ''
    $words = $rawWords -split ', *'
    $words
}

$definitions = @{}
foreach ($rawLine in $rawDictionaryLines) {
    $lineCount++
    $watchedWord = 'nope'
    if ($rawLine -match $watchedWord) {Write-Host "rawline is $rawLine"}
    ($rawForm, $rawWords) = $rawLine -split '  +', 2
    $form = Convert-RawToFormal -rawForm $rawForm
    $words = Get-Words -rawWords $rawWords
    foreach ($word in $words) {
        if ($word -match $watchedWord) {Write-Host "$word is with $form"}
        if (-not $form) {Write-Host "$word has no form"}
        if (-not $definitions.ContainsKey($word)) {
            $definitions[$word] = $form
        } else {
            # Write-Host ("`t`t`t'($word)' {'$form''$($definitions[$word])'}")    
            $preferredForm = Switch -Exact ($word) {
			    '(appropriate )' {'a-p-r-a'}
			    '(ad valorem)' {'a-d-<-v'}
			    '(chairman )' {'ch-m-a-n'}
			    '(Chosen)' {'ch-o-s-n'}
			    '(d-l-e-sh)' {'d-e-l-sh'}
			    '(department)' {'d-p-t-m'}
			    '(depot)' {'d-p-o'}
			    '(do)' {'d-u'}
			    '(ex officio)' {'e-s-o-f-e-s-o'}
			    '(experience )' {'s-p-e'}
			    '(God )' {'g-o-d'}
			    '(Hawaii )' {'^-h-\-a-u-i'}
			    '(conference )' {'k-f-e-r-s'}
			    '(community )' {'k-m-u/nt'}
			    '(lined)' {'l-a-nt'}
			    '(live)' {'l-a-v'}
			    '(May)' {'m-a'}
			    '(march)' {'m-a-ch'}
			    '(morocco)' {'m-o-r-o-k-o'}
			    '(induce)' {'nt-u-s'}
			    '(in other words )' {'n-u-d-s'}
			    '(northwest)' {'n-u-e-s'}
			    '(northwestern)' {'n-u-e-s-tn'}
			    '(post office)' {'p-/-o-s'}
			    '(product )' {'p-r-o-d'}
			    '(Rhode Island )' {'r-<-i'}
			    '(west)' {'u-e-s'}
			    '(western)' {'u-e-s-tn'}
			    '(year)' {'ye-r'}
                Default {$definitions[$word]}
            }
            $definitions[$word] = $preferredForm
        }
    }
}

$csvDefinitions = New-Object System.Collections.ArrayList
foreach ($definition in $definitions.GetEnumerator()) {
    if (-not $definition.value) {Write-Host "Problem with $($definition.key)"}

    $csvDefinitions.Add((New-Object PsCustomObject -Property @{
        'word'=$definition.key
        'formal'=$definition.value
        'lazy' = ''
        'keyer' = ''
        'usage' = ''
        'hint' = ''})) | Out-Null
}

$csvDefinitions | Sort-Object {$_.word}| Export-Csv -Path "$PSScriptRoot\anniversary_formals.csv" -NoTypeInformation

