
class DictionaryMap
{
	dictionaries := []
	dictionaryPickList := ""
	dictionaryFullToShortNames := {}
	dictionaryShortToFullNames := {}
	dictionariesLoaded := 0
	backupCount := 2
	retrains := {}
	negations := ComObjCreate("Scripting.Dictionary")
	qwerds := ComObjCreate("Scripting.Dictionary")
	hints := ComObjCreate("Scripting.Dictionary")
	displaceds := ComObjCreate("Scripting.Dictionary")
	
	logQueue := new Queue("DictionaryMapQueue")
	logVerbosity := 2
	
	__New(qenv)
	{
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
			Loop,Read, % loadDictionary   ;read dictionary into Scripting.Dictionaries 
			{
				NumLines:=A_Index-1
				IfEqual, A_Index, 1, Continue ; Skip title row
				newEntry := new DictionaryEntry(A_LoopReadLine "," loadDictionary)
				
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
				
				this.propagateEntryToMaps(newEntry)

			}
			this.logEvent(1, "Loaded dictionary " loadDictionary " resulting in " NumLines " entries")
		}
		this.dictionariesLoaded := 1
		;MsgBox, % "Dictionaries fully loaded"
	}
	
	propagateEntryToMaps(newEntry) {
		this.qwerds.item(newEntry.qwerd) := newEntry
		this.hints.item(newEntry.word) := newEntry
		
		StringUpper, qwerdUPPER, % newEntry.qwerd
		StringUpper, wordUPPER, % newEntry.word
		newEntryUPPER := new DictionaryEntry(wordUPPER "," newEntry.form "," qwerdUPPER "," newEntry.keyer "," newEntry.Usage "," newEntry.hint "," newEntry.dictionary)
		this.qwerds.item(qwerdUPPER) := newEntryUPPER
		this.hints.item(wordUPPER) := newEntryUPPER
		
		qwerdCapped := SubStr(qwerdUPPER, 1, 1) . SubStr(newEntry.qwerd, 2, (StrLen(newEntry.qwerd) - 1))
		wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(newEntry.word, 2, (StrLen(newEntry.word) - 1))
		newEntryCapped := new DictionaryEntry(wordCapped "," newEntry.form "," qwerdCapped "," newEntry.keyer "," newEntry.Usage "," newEntry.hint "," newEntry.dictionary)
		this.qwerds.item(qwerdCapped) := newEntryCapped
		this.hints.item(wordCapped) := newEntryCapped
		
		;Msgbox, % "Qwerds " newEntry.qwerd "," qwerdUPPER "," qwerdCapped
		;Msgbox, % "Words " newEntry.word "," wordUPPER "," wordCapped
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
		
		;Msgbox, % "Qwerds " newEntry.qwerd "," qwerdUPPER "," qwerdCapped
		;Msgbox, % "Words " newEntry.word "," wordUPPER "," wordCapped
	}	

	saveDictionaries() {
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
			header := "word,form,qwerd,keyer,usage,hint`n"
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
			dictline := qwerd.word "," qwerd.form "," qwerd.qwerd "," qwerd.keyer "," qwerd.usage "," qwerd.hint "`n"
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

LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("map",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
