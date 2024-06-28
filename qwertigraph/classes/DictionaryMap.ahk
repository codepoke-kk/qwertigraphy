
class DictionaryMap
{
	dictionaries := []
	dictionaryPickList := ""
	dictionaryFullToShortNames := {}
	dictionaryShortToFullNames := {}
	chordOrder := "gtrfedwsqazxcvhyujikolpmnb"
	minimumChordLength := 2
	maximumChordUsage := 10000
	dictionariesLoaded := 0
	longestQwerd := 0
	backupCount := 2
	retrains := {}
	negations := ComObjCreate("Scripting.Dictionary")
	negationsChords := ComObjCreate("Scripting.Dictionary")
	qwerds := ComObjCreate("Scripting.Dictionary")
	chords := ComObjCreate("Scripting.Dictionary")
	hints := ComObjCreate("Scripting.Dictionary")
	displaceds := ComObjCreate("Scripting.Dictionary")
	prefixes := ComObjCreate("Scripting.Dictionary")
	suffixes := ComObjCreate("Scripting.Dictionary")

	logQueue := new Queue("DictionaryMapQueue")
	logVerbosity := 2

	__New(qenv)
	{
        local fields
		this.qenv := qenv
		this.logVerbosity := this.qenv.properties.LoggingLevelMap

		; Create the array of dictionary files to be loaded
		this.logEvent(1, "Loading dictionaries list from " this.qenv.dictionaryListFile)
		Loop, read, % this.qenv.dictionaryListFile
		{
			if (! RegexMatch(A_LoopReadLine, "^;")) {
				this.logEvent(2, "Adding dictionary " A_LoopReadLine)
				personalizedDict := RegExReplace(A_LoopReadLine, "AppData", this.qenv.personalDataFolder)
				this.dictionaries.Push(personalizedDict)
				dictShortName := RegExReplace(personalizedDict, "^(.*\\)", "")
				this.dictionaryFullToShortNames[personalizedDict] := dictShortName
				this.dictionaryPickList := this.dictionaryPickList "|" dictShortName
				this.dictionaryShortToFullNames[dictShortName] := personalizedDict
			} else {
				this.logEvent(2, "Skipping dictionary " A_LoopReadLine)
			}
		}

		; Read in the negations (case sensitive words to never load)
		this.logEvent(2, "Loading negations from " this.qenv.negationsFile)
		Loop,Read, % this.qenv.negationsFile   ;read negations
		{
			this.logEvent(4, "Loading negation " A_LoopReadLine)
			this.negations.item(A_LoopReadLine) := 1
		}
		; Read in the prefixes (expansions keyed by a trailing semicolon)
		this.logEvent(2, "Loading prefixes from " this.qenv.prefixesFile)
		Loop,Read, % this.qenv.prefixesFile   ;read prefixes
		{
			this.logEvent(4, "Loading prefix " A_LoopReadLine)
            ;prefix_line := StrReplace(A_LoopReadLine, """", "")
            prefix_fields := StrSplit(A_LoopReadLine, ",")
			this.logEvent(3, "Loading " prefix_fields[1] " as " prefix_fields[2])
			this.prefixes.item(prefix_fields[1]) := prefix_fields[2]
            StringUpper, titled_prefix_key, % prefix_fields[1], T
            StringUpper, titled_prefix_value, % prefix_fields[2], T
			this.logEvent(3, "Loading " titled_prefix_key " as " titled_prefix_value)
			this.prefixes.item(titled_prefix_key) := titled_prefix_value
		}
		; Read in the suffixes (expansions keyed by a leading semicolon)
		this.logEvent(2, "Loading suffixes from " this.qenv.suffixesFile)
		Loop,Read, % this.qenv.suffixesFile   ;read suffixes
		{
			this.logEvent(4, "Loading suffix " A_LoopReadLine)
            ;suffix_line := StrReplace(A_LoopReadLine, """", "")
            suffix_fields := StrSplit(A_LoopReadLine, ",")
			this.logEvent(3, "Loading " suffix_fields[1] " as " suffix_fields[2])
			this.suffixes.item(suffix_fields[1]) := suffix_fields[2]
            StringUpper, titled_suffix_key, % suffix_fields[1], T
            StringUpper, titled_suffix_value, % suffix_fields[2], T
			this.logEvent(3, "Loading " titled_suffix_key " as " titled_suffix_value)
			this.suffixes.item(titled_suffix_key) := titled_suffix_value
		}
		; Read in the negations for chords (case insensitive chords to never load)
		this.logEvent(2, "Loading negations for chords from " this.qenv.negationsChordsFile)
		Loop,Read, % this.qenv.negationsChordsFile   ;read negations
		{
			this.logEvent(4, "Loading negation chord " A_LoopReadLine)
			this.negationsChords.item(A_LoopReadLine) := 1
		}
		; Read in the retrains (words to flag when used, usually to break a bad habit)
		this.logEvent(2, "Loading retrains from " this.qenv.retrainsFile)
		Loop,Read, % this.qenv.retrainsFile   ;read retrains
		{
			this.logEvent(4, "Loading retrain " A_LoopReadLine)
			this.retrains[A_LoopReadLine] := 1
		}

		; Considering retrains and negations, load all definitions
		for index, loadDictionary in this.dictionaries
		{
			this.logEvent(2, "Loading dictionary " loadDictionary)
			; preload variable as false to capture any event making it true
			upgradeToV2Happened := false
			Loop,Read, % loadDictionary   ;read dictionary into Scripting.Dictionaries
			{
				NumLines:=A_Index-1
				if (A_Index = 1) {
					; We do nothing with the title row, except check to see whether this is a v2 dictionary
					if (A_LoopReadLine ~= "hint") {
						this.logEvent(1, loadDictionary " is v1 and must be upgrade to v2")
						this.upgradeDictionaryToV2(loadDictionary)
						upgradeToV2Happened := true
					}
					Continue
				}

				if (upgradeToV2Happened) {
					Continue
				}

				newEntry := new DictionaryEntry(A_LoopReadLine "," loadDictionary)
                this.logEvent(4, "Spawned " newEntry.qwerd " as " newEntry.word "," newEntry.chord "," newEntry.usage "," newEntry.hint " from " A_LoopReadLine)

				if (this.qwerds.item(newEntry.qwerd).word) {
					; If we already have this one, keep it as a displaced entry, but do not overwrite the existing entry
					this.displaceds.item(newEntry.qwerd) := newEntry
					continue
				}
				if (this.negations.item(newEntry.qwerd)) {
					; If this one is in the negations list, keep it as a displaced entry, but do not overwrite the existing entry
					this.displaceds.item(newEntry.qwerd) := newEntry
					continue
				}

				if (StrLen(newEntry.qwerd) > this.longestQwerd) {
					this.longestQwerd := StrLen(newEntry.qwerd)
				}

				this.propagateEntryToMaps(newEntry)

			}
			this.logEvent(1, "Loaded dictionary " loadDictionary " resulting in " NumLines " entries")
		}

		if (upgradeToV2Happened) {
			Msgbox, % "After dictionary upgrade, you must restart this script. Please close it and restart it"
		}
		this.dictionariesLoaded := 1
		;MsgBox, % "Dictionaries fully loaded"
	}

	propagateEntryToMaps(newEntry) {
		this.logEvent(4, "Propagating " newEntry.qwerd " as " newEntry.word "," newEntry.chord "," newEntry.usage "," newEntry.hint)
        ; Evaluate chordability first
		; Limit chord acceptance by length, by frequency of usage, and to only appear once
		if (StrLen(newEntry.chord) >= this.minimumChordLength) {
			if (not this.chords.item(newEntry.chord).word) {
                if (SubStr(newEntry.chord, 1, 1) == "q") {
                    chordability := "blocked"
				} else if (newEntry.Usage < this.maximumChordUsage) {
					chordability := "active"
				} else {
					chordability := "rare"
                    this.logEvent(2, "Chordability of " newEntry.chord " is rare - you might need to modify its Usage manually")
				}
			} else {
				chordability := "unused"
			}
		} else {
			chordability := "short"
		}
        newEntry.chordable := chordability

        if (newEntry.chord == "0av") {
            this.logEvent(1, "Chordability of 0av is "  chordability)
        }

		; Force lower entries to lower
		StringLower, qwerdlower, % newEntry.qwerd
		StringLower, wordlower, % newEntry.word
		newEntrylower := new DictionaryEntry(wordlower "," newEntry.form "," qwerdlower "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntrylower.chordable := chordability
		if (not this.negations.item(qwerdlower)) {
			this.qwerds.item(qwerdlower) := newEntrylower
		}

		; Force upper entries to upper
		StringUpper, qwerdUPPER, % newEntry.qwerd
		StringUpper, wordUPPER, % newEntry.word
		newEntryUPPER := new DictionaryEntry(wordUPPER "," newEntry.form "," qwerdUPPER "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntryUPPER.chordable := chordability
		if (not this.negations.item(qwerdUPPER)) {
			this.qwerds.item(qwerdUPPER) := newEntryUPPER
		}

		; Allow single-capped entries to use full proper casing all the way through as given
		qwerdCapped := SubStr(qwerdUPPER, 1, 1) . SubStr(newEntry.qwerd, 2, (StrLen(newEntry.qwerd) - 1))
		wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(newEntry.word, 2, (StrLen(newEntry.word) - 1))
		newEntryCapped := new DictionaryEntry(wordCapped "," newEntry.form "," qwerdCapped "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntryCapped.chordable := chordability
		if (not this.negations.item(qwerdCapped)) {
			this.qwerds.item(qwerdCapped) := newEntryCapped
		}

		; With multiple qwerds possible for a word, we have to pick the right one to hint.
		if (not this.hints.item(newEntry.word).word) {
			; If we don't already have a hint, then this is the one
			this.hints.item(wordlower) := newEntrylower
			this.hints.item(wordUPPER) := newEntryUPPER
			this.hints.item(wordCapped) := newEntryCapped
		} else if (this.hints.item(newEntry.word).qwerd == newEntry.qwerd) {
			; if the current hint is for this form, then update the current entry
			this.hints.item(wordlower) := newEntrylower
			this.hints.item(wordUPPER) := newEntryUPPER
			this.hints.item(wordCapped) := newEntryCapped
		} ; If the current hint is for another form of the word, then do nothing

        if (chordability == "active") {
			if (not this.negationsChords.item(newEntrylower.chord)) {
				if (newEntry.isCamel) {
					this.logEvent(4, "Adding capped chord " newEntryCapped.chord " as " newEntryCapped.word)
					this.chords.item(newEntry.chord) := newEntryCapped
				} else {
					this.logEvent(4, "Adding lowered chord " newEntrylower.chord " as " newEntrylower.word)
					this.chords.item(newEntry.chord) := newEntrylower
				}

				StringUpper, chordUPPER, % newEntrylower.chord
				newChordEntryCapped := new DictionaryEntry(wordCapped "," newEntrylower.form "," chordUPPER "," newEntrylower.keyer "," newEntrylower.chord "," newEntrylower.usage "," newEntrylower.dictionary)
				newChordEntryCapped.chord := chordUPPER
				newChordEntryCapped.chordable := "active"
				this.chords.item(newChordEntryCapped.chord) := newChordEntryCapped
				this.logEvent(3, "Added chord " newChordEntryCapped.chord " as " newChordEntryCapped.word)
			} else {
				this.logEvent(1, "Declining to add chord " newEntrylower.chord " as " newEntrylower.word " due to prevention in negations_chords.txt")
			}
        }

        this.logEvent(4, "Marked qwerd " newEntry.qwerd "'s chord " newEntry.chord " as " newEntry.chordable)
		this.qenv.editor.updateEditsStatus("Pending")
        this.logEvent(4, "Marked edits pending")


	}

	deleteQwerdFromMaps(qwerdKey) {
		this.logEvent(1, "Deleting entries related to " qwerdKey)
		oldEntry := this.qwerds.item(qwerdKey)
		this.qwerds.remove(qwerdKey)
		; If the same word is deleted under two different qwerds, the hint is whacked
		if (this.hints.item(oldEntry.word)) {
			this.hints.remove(oldEntry.word)
		}

		StringUpper, qwerdUPPER, % oldEntry.qwerd
		StringUpper, wordUPPER, % oldEntry.word
		this.qwerds.remove(qwerdUPPER)
		if (this.hints.item(wordUPPER)) {
			this.hints.remove(wordUPPER)
		}

		qwerdCapped := SubStr(qwerdUPPER, 1, 1) . SubStr(oldEntry.qwerd, 2, (StrLen(oldEntry.qwerd) - 1))
		wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(oldEntry.word, 2, (StrLen(oldEntry.word) - 1))
		this.qwerds.remove(qwerdCapped)
		if (this.hints.item(wordCapped)) {
			this.hints.remove(wordCapped)
		}
		this.qenv.editor.updateEditsStatus("Pending")
        this.logEvent(4, "Marked edits pending")
	}

	AlphaOrder(input_text) {
		chord := ""
		loop, parse, input_text
			chord .= A_LoopField ","

		Sort, chord, UD,
		return StrReplace(chord, ",")
	}

	ChordSort(a1, a2) {
		; This takes 3-6 times as long as a simple alpha sort. Only use for one-time functions
		return InStr(this.ChordOrder, a1) - InStr(this.ChordOrder, a2)
	}

	saveDictionaries() {
		local dictline
		this.logEvent(1, "Saving dictionaries")
		if ( not this.dictionariesLoaded ) {
			this.logEvent(1, "Dictionaries not yet loaded. Stopping")
			Msgbox, % "Please wait for all dictionaries to load"
			Return
		}

		; Backup all dictionary files with this date stamp, unless already done
		; Keep 1 backup per hour
		FormatTime, bakDateStamp, , yyyyMMddHH
		for dictIndex, dictionary in this.dictionaries {
			bakdict := dictionary . "." . bakDateStamp . ".bak"
			this.logEvent(1, "Backing up " bakdict)
			if ( not FileExist(bakdict) ) {
				; Msgbox, % "Backing up " dictionary " to " bakdict
				FileCopy, %dictionary%, %bakdict%
			}
		}

		; Removed unwanted backups
		; GuiControlGet BackupCount
		for dictIndex, dictionary in this.dictionaries {
			this.logEvent(2, "Trimming backups in " dictionary)
			FileList := ""
			Loop, Files, %dictionary%*.bak, F  ; Include Files and Directories
				FileList .= A_LoopFileTimeModified "`t" A_LoopFilePath "`n"

			retainedCount := 0
			Sort, FileList, R ; Sort by date.
			Loop, Parse, FileList, `n
			{
				retainedCount += 1
				if (A_LoopField = "")  ; Omit the last linefeed (blank item) at the end of the list.
					continue
				StringSplit, FileItem, A_LoopField, %A_Tab%  ; Split into two parts at the tab char.
				this.logEvent(2, "The next backup from " FileItem1 " is: " FileItem2)
				if (this.backupCount >= retainedCount) {
					this.logEvent(2, "Retaining " FileItem2)
				} else {
					this.logEvent(2, "Deleting " FileItem2)
					FileDelete, %FileItem2%
				}
			}
		}

		; Create a new array with sortable, proper cased qwerds by prepending the usage number
		sortableForms := {}
		sortedCount := 0
		for word in this.qwerds {
			qwerd := this.qwerds.item(word)
			if (not qwerd.isProper) {
				this.logEvent(4, "Skipping qwerd for not being propercase " qwerd.qwerd)
				continue
			} else {
				this.logEvent(4, "Keeping qwerd for being propercase " qwerd.qwerd)
			}
			sortedCount += 1
			sortableKey :=  SubStr("0000000", StrLen(qwerd.usage)) qwerd.usage "_" qwerd.qwerd
			sortableForms[sortableKey] := qwerd
			if (qwerd.word = "look" or qwerd.word = "execution" or qwerd.word = "services") {
				this.logEvent(1, "Created sortable for " sortableKey " as " sortableForms[sortableKey].qwerd)
			}
			this.logEvent(4, "Created sortable " sortableForms[sortableKey].qwerd)
		}
		; Keep words that were in a dictionary, but displaced by words in a higher priority dictionary
		for word in this.displaceds {
			qwerd := this.displaceds.item(word)
			if (not qwerd.isProper) {
				this.logEvent(4, "Skipping qwerd for not being propercase " qwerd.qwerd)
				continue
			} else {
				this.logEvent(4, "Keeping qwerd for being propercase " qwerd.qwerd)
			}
			sortedCount += 1
			sortableKey :=  SubStr("0000000", StrLen(qwerd.usage)) qwerd.usage "_" qwerd.qwerd
			sortableForms[sortableKey] := qwerd
			if (qwerd.word = "look" or qwerd.word = "execution" or qwerd.word = "services") {
				this.logEvent(1, "Created displaced sortable for " sortableKey " as " sortableForms[sortableKey].qwerd)
			}
			this.logEvent(4, "Created displaced sortable " sortableForms[sortableKey].qwerd)
		}
		this.logEvent(2, "Saving " sortedCount " qwerds")

		; Open all the dictionaries for writing
		filehandles := {}
		for index, dictionary in this.dictionaries
		{
			newdict := dictionary . ".new"
			filehandle := FileOpen(newdict, "w")
			filehandles[dictionary] := filehandle
			header := "word,form,qwerd,keyer,chord,usage`n"
			filehandles[dictionary].Write(header)
            this.logEvent(2, "Writing to new dictionary " newdict)
		}

		; Loop across the sorted forms and write them
		; Write each to its own dictionary
		writtenCount := 0
		; GuiControl,Show, SaveProgress
		for sortableKey, qwerd in sortableForms {
			this.logEvent(4, "Writing " sortableKey)
			writtenCount += 1
			; progress := Round(100*(writtenCount/sortedCount))
			; GuiControl,, SaveProgress, %progress%
			; msgbox, % "Looping with " sortableKey "=" form.word
			dictline := qwerd.word "," qwerd.form "," qwerd.qwerd "," qwerd.keyer "," qwerd.chord "," qwerd.usage "`n"
			this.logEvent(4, "Writing " dictline " to " qwerd.dictionary)
			if (qwerd.word = "Changed" or qwerd.word = "Called" or qwerd.word = "Looked") {
				this.logEvent(1, "Writing sortable for " dictline " to " qwerd.dictionary)
			}
			filehandles[qwerd.dictionary].Write(dictline)
		}
		this.logEvent(2, "Wrote " writtenCount " qwerds")

		; Close all the dictionaries
		for index, dictionary in this.dictionaries
		{
			this.logEvent(2, "Closing " dictionary)
			filehandles[dictionary].Close()
		}

		; Overwrite the current dictionaries with the new
		for dictIndex, dictionary in this.dictionaries {
			newdict := dictionary . ".new"
			this.logEvent(1, "Permanently copying " newdict " as " dictionary)
			FileCopy, %newdict%, %dictionary%, true
			FileDelete, %newdict%
		}



		; Open the export dictionary for writing
		exportdict := "qwertigraph.export"
		filehandle := FileOpen(exportdict, "w")
		filehandles[exportdict] := filehandle
		header := "word,form,qwerd,keyer,chord,usage`n"
		filehandles[exportdict].Write(header)
		this.logEvent(2, "Writing to export dictionary " exportdict)

		for word in this.qwerds {
			qwerd := this.qwerds.item(word)
			if (not qwerd.isLower) {
				this.logEvent(4, "Skipping qwerd for not being lowercase " qwerd.qwerd)
				continue
			} else if (qwerd.usage > 40000) {
				this.logEvent(4, "Skipping qwerd for not being used " qwerd.usage)
				continue
			} else {
				this.logEvent(4, "Keeping qwerd for being willofoutercase " qwerd.qwerd)
			}
			dictline := qwerd.word "," qwerd.form "," qwerd.qwerd "," qwerd.keyer "," qwerd.chord "," qwerd.usage "`n"
			this.logEvent(4, "Writing " dictline " to " exportdict)
			; Also write to the export dictionary
			filehandles[exportdict].Write(dictline)
		}

		filehandles[exportdict].Close()

		this.qenv.editor.updateEditsStatus("Saved")
        this.logEvent(4, "Marked edits saved")
	}

	upgradeDictionaryToV2(dictionary) {
        local line
		this.logEvent(2, "Upgrading " dictionary " to v2")

		; First create a backup of the v1 dictionary
		backupdict := dictionary . ".v1backup"
		newdict := dictionary . ".v2temp"
		this.logEvent(2, "Backing up old " dictionary " as " backupdict)
		FileCopy, %dictionary%, %backupdict%, true

		fileHandle := FileOpen(newdict, "w")
		header := "word,form,qwerd,keyer,chord,usage`n"
		fileHandle.Write(header)

		; Next read in the rows of the dictionary
		Loop,Read, % dictionary
		{
			if (A_Index = 1) {
				continue
			}
			line := StrReplace(A_LoopReadLine, """", "")
			fields := StrSplit(line, ",")
			entry := {}
			entry.word := fields[1]
			entry.form := fields[2]
			entry.qwerd := fields[3]
			entry.keyer := fields[4]
			entry.usage := fields[5]
			entry.hint := fields[6]
			entry.chord := this.AlphaOrder(entry.qwerd)

			dictline := entry.word "," entry.form "," entry.qwerd "," entry.keyer "," entry.chord "," entry.usage "`n"
			fileHandle.Write(dictline)
		}

		fileHandle.Close()

		this.logEvent(1, "Permanently copying " newdict " as " dictionary)
		FileCopy, %newdict%, %dictionary%, true
		FileDelete, %newdict%
	}

LogEvent(verbosity, message)
	{
		if (verbosity <= this.logVerbosity)
		{
			event := new LoggingEvent("map",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
