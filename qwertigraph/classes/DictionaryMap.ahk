
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
	
	logQueue := new Queue("DictionaryMapQueue")
	logVerbosity := 1
	
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
					; If we already have this one, do not overwrite the existing entry
					continue
				}
				if (this.negations.item(newEntry.qwerd)) {
					; If this one is in the negations list, do not add it 
					continue
				}
				
				this.propagateEntryToMaps(newEntry)

			}
			this.logEvent(1, "Loaded dictionary " loadDictionary " resulting in " NumLines " entries")
		}
		this.dictionariesLoaded := 1
	}
	
	propagateEntryToMaps(newEntry) {
		this.qwerds.item(newEntry.qwerd) := newEntry
		this.hints.item(newEntry.word) := newEntry
		
		StringUpper, qwerdUPPER, % newEntry.qwerd
		StringUpper, wordUPPER, % newEntry.word
		newEntryUPPER := new DictionaryEntry(wordUPPER "," newEntry.form "," qwerdUPPER "," newEntry.keyer "," newEntry.Usage "," newEntry.hint)
		this.qwerds.item(qwerdUPPER) := newEntryUPPER
		this.hints.item(wordUPPER) := newEntryUPPER
		
		qwerdCapped := SubStr(qwerdUPPER, 1, 1) . SubStr(newEntry.qwerd, 2, (StrLen(newEntry.qwerd) - 1))
		wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(newEntry.word, 2, (StrLen(newEntry.word) - 1))
		newEntryCapped := new DictionaryEntry(wordCapped "," newEntry.form "," qwerdCapped "," newEntry.keyer "," newEntry.Usage "," newEntry.hint)
		this.qwerds.item(qwerdCapped) := newEntryCapped
		this.hints.item(wordCapped) := newEntryCapped
		
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
		
		Return
		
;		; Removed unwanted backups
;		; GuiControlGet BackupCount
;		for dictIndex, dictionary in dictionaries {
;			logEventDE(2, "Trimming backups in " dictionary)
;			FileList := ""
;			Loop, Files, %dictionary%*.bak, F  ; Include Files and Directories
;				FileList .= A_LoopFileTimeModified "`t" A_LoopFileName "`n"
;				
;			retainedCount := 0
;			Sort, FileList, R ; Sort by date.
;			Loop, Parse, FileList, `n
;			{
;				retainedCount += 1
;				if (A_LoopField = "")  ; Omit the last linefeed (blank item) at the end of the list.
;					continue
;				StringSplit, FileItem, A_LoopField, %A_Tab%  ; Split into two parts at the tab char.
;				logEventDE(2, "The next backup from " FileItem1 " is: " FileItem2)
;				if (BackupCount >= retainedCount) {
;					logEventDE(2, "Retaining " FileItem2)
;				} else {
;					logEventDE(2, "Deleting " FileItem2)
;					FileDelete, %PersonalDataFolder%\%FileItem2%
;				}
;			}
;		}
;		
;		; Create a new array with sortable names by prepending the usage number 
;		sortableForms := {}
;		sortedCount := 0
;		for word, form in forms {
;			sortedCount += 1
;			sortableKey :=  SubStr("0000000", StrLen(form.usage)) form.usage "_" form.word
;			sortableForms[sortableKey] := form
;			; msgbox, % "created " sortableForms[sortableKey].lazy   
;		}
;		
;		; Open all the dictionaries for writing
;		fileHandles := {}
;		for index, dictionary in dictionaries
;		{
;			newdict := dictionary . ".new"
;			fileHandle := FileOpen(newdict, "w")
;			fileHandles[dictionary] := fileHandle
;			header := "word,formal,lazy,keyer,usage,hint`n"
;			fileHandles[dictionary].Write(header)
;		}
;		
;		; Loop across the sorted forms and write them 
;		; Write each to its own dictionary 
;		writtenCount := 0
;		GuiControl,Show, SaveProgress 
;		for sortableKey, form in sortableForms {
;			writtenCount += 1
;			progress := Round(100*(writtenCount/sortedCount))
;			GuiControl,, SaveProgress, %progress%  
;			; msgbox, % "Looping with " sortableKey "=" form.word
;			line := form.word "," form.formal "," form.lazy "," form.keyer "," form.usage "," form.hint "`n"
;			fileHandles[form.dictionary].Write(line)
;		}
;		
;		; Close all the dictionaries 
;		for index, dictionary in dictionaries
;		{
;			fileHandles[dictionary].Close()
;		}
;		
;		; Overwrite the current dictionaries with the new
;		for dictIndex, dictionary in dictionaries {
;			logEventDE(1, "Permanently copying " newdict)
;			newdict := dictionary . ".new"
;			logEventDE(1, "Permanently copying " newdict " as " dictionary)
;			FileCopy, %newdict%, %dictionary%, true
;			FileDelete, %newdict%
;		}
;
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
