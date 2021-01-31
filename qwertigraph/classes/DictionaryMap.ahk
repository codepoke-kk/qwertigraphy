
class DictionaryMap
{
	dictionaries := []
	dictionariesLoaded := 0
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
			Loop,Read, % loadDictionary   ;read dictionary into HotStrings
			{
				NumLines:=A_Index-1
				IfEqual, A_Index, 1, Continue ; Skip title row
				newEntry := new DictionaryEntry(A_LoopReadLine)
				
				if (this.qwerds.item(newEntry.qwerd).word) {
					continue
				}
				
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
			this.logEvent(1, "Loaded dictionary " loadDictionary " resulting in " NumLines " entries")
		}
	}
	
	CreateFormsFromDictionary() 
	{
		; no op
	}	
	LaunchCoach() 
	{
		; no op
	}
	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("map",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
	CSobj() {
    static base := object("_NewEnum","__NewEnum", "Next","__Next", "__Set","__Setter", "__Get","__Getter")
    return, object("__sd_obj__", ComObjCreate("Scripting.Dictionary"), "base", base)
	}
		__Getter(self, key) {
			return, self.__sd_obj__.item(key)
		}
		__Setter(self, key, value) {
			self.__sd_obj__.item(key) := value
			return, false
		}
		__NewEnum(self) {
			return, self
		}
		__Next(self, ByRef key = "", ByRef val = "") {
			static Enum
			if not Enum
				Enum := self.__sd_obj__._NewEnum
			if Not Enum[key], val:=self[key]
				return, Enum:=false
			return, true
		}
}
