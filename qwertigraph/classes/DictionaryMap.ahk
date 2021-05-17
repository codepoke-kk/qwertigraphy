
class DictionaryMap
{
	dictionaries := []
	dictionaryPickList := ""
	dictionaryFullToShortNames := {}
	dictionaryShortToFullNames := {}
	minimumChordLength := 3
	maximumChordUsage := 10000
	dictionariesLoaded := 0
	longestQwerd := 0
	backupCount := 2
	retrains := {}
	negations := ComObjCreate("Scripting.Dictionary")
	qwerds := ComObjCreate("Scripting.Dictionary")
	chords := ComObjCreate("Scripting.Dictionary")
	hints := ComObjCreate("Scripting.Dictionary")
	displaceds := ComObjCreate("Scripting.Dictionary")
	
	logQueue := new Queue("DictionaryMapQueue")
	logVerbosity := 1
	
	__New(qenv)
	{
        local fields
		this.qenv := qenv
		
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
				
				; Give the new entry a chord
				newEntry.chord := this.AlphaOrder(newEntry.qwerd)
				
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
        ; Evaluate chordability first
		; Limit chord acceptance by length, by frequency of usage, and to only appear once 
		if (StrLen(newEntry.chord) >= this.minimumChordLength) {
			If (not this.chords.item(newEntry.chord).word) {
				if (newEntry.Usage < this.maximumChordUsage) { 
					chordability := "active"
				} else { 
					chordability := "rare"
				}
			} else { 
				chordability := "unused"
			}
		} else { 
			chordability := "short"
		}
        newEntry.chordable := chordability
        
		; Force lower entries to lower
		StringLower, qwerdlower, % newEntry.qwerd
		StringLower, wordlower, % newEntry.word
		newEntrylower := new DictionaryEntry(wordlower "," newEntry.form "," qwerdlower "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntrylower.chordable := chordability
		this.qwerds.item(newEntry.qwerd) := newEntrylower
		this.hints.item(newEntry.word) := newEntrylower
		
		StringUpper, qwerdUPPER, % newEntry.qwerd
		StringUpper, wordUPPER, % newEntry.word
		newEntryUPPER := new DictionaryEntry(wordUPPER "," newEntry.form "," qwerdUPPER "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntryUPPER.chordable := chordability
		this.qwerds.item(qwerdUPPER) := newEntryUPPER
		this.hints.item(wordUPPER) := newEntryUPPER
		
		qwerdCapped := SubStr(qwerdUPPER, 1, 1) . SubStr(newEntry.qwerd, 2, (StrLen(newEntry.qwerd) - 1))
		wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(newEntry.word, 2, (StrLen(newEntry.word) - 1))
		newEntryCapped := new DictionaryEntry(wordCapped "," newEntry.form "," qwerdCapped "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
        newEntryCapped.chordable := chordability
		this.qwerds.item(qwerdCapped) := newEntryCapped
		this.hints.item(wordCapped) := newEntryCapped
		
        if (chordability == "active") {
            this.logEvent(4, "Adding chord " newEntry.chord " as " newEntry.word) 
            this.chords.item(newEntry.chord) := newEntry
            
            StringUpper, chordUPPER, % newEntry.chord
            newChordEntryCapped := new DictionaryEntry(wordCapped "," newEntry.form "," chordUPPER "," newEntry.keyer "," newEntry.chord "," newEntry.usage "," newEntry.dictionary)
            newChordEntryCapped.chord := chordUPPER
            newChordEntryCapped.chordable := "active"
            this.chords.item(newChordEntryCapped.chord) := newChordEntryCapped
            this.logEvent(4, "Added chord " newChordEntryCapped.chord " as " newChordEntryCapped.word)
        }
        
        this.logEvent(4, "Marked qwerd " newEntry.qwerd "'s chord " newEntry.chord " as " newEntry.chordable) 
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
	}	
	
	AlphaOrder(input_text) {		
		chord := ""
		loop, parse, input_text
			chord .= A_LoopField ","
		
		Sort, chord, UD,
		return StrReplace(chord, ",")
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
		
		; Create a new array with sortable, lowercase-only qwerds by prepending the usage number 
		sortableForms := {}
		sortedCount := 0
		for word, garbage in this.qwerds {
			qwerd := this.qwerds.item(word)
			if (not qwerd.isLower) {
				this.logEvent(4, "Skipping qwerd for not being lowercase " qwerd.qwerd)
				continue
			} else {
				this.logEvent(4, "Keeping qwerd for being lowercase " qwerd.qwerd)
			}
			sortedCount += 1
			sortableKey :=  SubStr("0000000", StrLen(qwerd.usage)) qwerd.usage "_" qwerd.word
			sortableForms[sortableKey] := qwerd
			if (qwerd.word = "look" or qwerd.word = "execution" or qwerd.word = "services") {
				this.logEvent(1, "Created sortable for " sortableKey " as " sortableForms[sortableKey].qwerd)  
			}
			this.logEvent(4, "Created sortable " sortableForms[sortableKey].qwerd)   
		}
		; Keep words that were in a dictionary, but displaced by words in a higher priority dictionary
		for word, garbage in this.displaceds {
			qwerd := this.displaceds.item(word)
			if (not qwerd.isLower) {
				this.logEvent(4, "Skipping qwerd for not being lowercase " qwerd.qwerd)
				continue
			} else {
				this.logEvent(4, "Keeping qwerd for being lowercase " qwerd.qwerd)
			}
			sortedCount += 1
			sortableKey :=  SubStr("0000000", StrLen(qwerd.usage)) qwerd.usage "_" qwerd.word
			sortableForms[sortableKey] := qwerd
			if (qwerd.word = "look" or qwerd.word = "execution" or qwerd.word = "services") {
				this.logEvent(1, "Created displaced sortable for " sortableKey " as " sortableForms[sortableKey].qwerd)  
			}
			this.logEvent(4, "Created displaced sortable " sortableForms[sortableKey].qwerd)   
		}
		this.logEvent(2, "Saving " sortedCount " qwerds")
		
		; Open all the dictionaries for writing
		fileHandles := {}
		for index, dictionary in this.dictionaries
		{
			newdict := dictionary . ".new"
			fileHandle := FileOpen(newdict, "w")
			fileHandles[dictionary] := fileHandle
			header := "word,form,qwerd,keyer,chord,usage`n"
			fileHandles[dictionary].Write(header)
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
			if (qwerd.word = "look" or qwerd.word = "execution" or qwerd.word = "services") {
				this.logEvent(1, "Writing sortable for " dictline " to " qwerd.dictionary)  
			}
			fileHandles[qwerd.dictionary].Write(dictline)
		}
		this.logEvent(2, "Wrote " writtenCount " qwerds")
		
		; Close all the dictionaries 
		for index, dictionary in this.dictionaries
		{
			this.logEvent(2, "Closing " dictionary)
			fileHandles[dictionary].Close()
		}
		
		; Overwrite the current dictionaries with the new
		for dictIndex, dictionary in this.dictionaries {
			newdict := dictionary . ".new"
			this.logEvent(1, "Permanently copying " newdict " as " dictionary)
			FileCopy, %newdict%, %dictionary%, true
			FileDelete, %newdict%
		}

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
