
class QwertigraphyEnvironment
{
	personalizedFiles := {"templates\personal.template":"personal.csv", "templates\dictionary_load.template":"dictionary_load.list", "templates\negations.template":"negations.txt","templates\negations_chords.template":"negations_chords.txt", "templates\retrains.template":"retrains.txt", "templates\personal_functions.template":"personal_functions.ahk", "templates\qwertigraph.template":"qwertigraph.properties"}
	personalDataFolder := A_AppData "\Qwertigraph"
	dictionaryListFile := this.personalDataFolder "\dictionary_load.list"
	negationsFile := this.personalDataFolder "\negations.txt"
	negationsChordsFile := this.personalDataFolder "\negations_chords.txt"
	retrainsFile := this.personalDataFolder "\retrains.txt"
	propertiesFile := this.personalDataFolder "\qwertigraph.properties"
	properties := {}
	
	strokepathsFile := "strokepaths\gregg.esv"
	strokepaths := ComObjCreate("Scripting.Dictionary")
	
    desensitizedQwerd := new DashboardEvent("****", "****", "****", "****")
	
	logQueue := new Queue("QEnvQueue")
	logVerbosity := 2
	
	__New()
	{
		; Personalize this user's data by creating the personal folder 
		this.logEvent(1, "Personal data found at " this.personalDataFolder)
		IfNotExist, % this.PersonalDataFolder
		{
			FileCreateDir, % this.personalDataFolder
			this.logEvent(2, "Created " this.personalDataFolder)
		}
		
		; The personal folder exists, now copy files out to it as needed 
		for fileKey, fileValue in this.personalizedFiles
		{
			IfNotExist, % this.personalDataFolder "\" fileValue
			{
				FileCopy, % fileKey, % this.personalDataFolder "\" fileValue, false
				this.logEvent(1, "Created " fileKey " as " this.personalDataFolder "\" fileValue)
			}
		}
		
		; Read in the environment from properties
		Loop,Read, % this.propertiesFile   
		{
			if (A_Index = 1) {
				Continue 
			}
			prop_fields := StrSplit(A_LoopReadLine, ",")
			this.properties[prop_fields[1]] := prop_fields[2]
		}
		
		this.injectMissingProperties()
		
		; Read in the strokepaths
		Loop,Read, % this.strokepathsFile   
		{
			if (A_Index = 1) {
				Continue 
			}
			this.logEvent(4, "Reviewing strokes line " A_LoopReadLine)
			strokefields := StrSplit(A_LoopReadLine, "=")
			this.logEvent(4, "Split to " strokefields[1] " | " strokefields[2] )
			strokepath := {"path": strokefields[1], "pattern": strokefields[2]}
			this.strokepaths.item(strokepath.pattern) := strokepath
		}
		this.logEvent(2, "Created " this.strokepaths.Count " strokepaths")
	}
	
	injectMissingProperties() {
		if (not this.properties.ChordWindow) {
			this.properties.ChordWindow := 300
		}
		if (not this.properties.CoachAheadLines) {
			this.properties.CoachAheadLines := 100
		}
		if (not this.properties.CoachAheadTipDuration) {
			this.properties.CoachAheadTipDuration := 5000
		}
		if (not this.properties.CoachAheadWait) {
			this.properties.CoachAheadWait := 1000
		}
		if (not this.properties.LoggingLevelCoach) {
			this.properties.LoggingLevelCoach := 1
		}
		if (not this.properties.LoggingLevelEditor) {
			this.properties.LoggingLevelEditor := 1
		}
		if (not this.properties.LoggingLevelEngine) {
			this.properties.LoggingLevelEngine := 1
		}
		if (not this.properties.LoggingLevelMap) {
			this.properties.LoggingLevelMap := 1
		}
		if (not this.properties.LoggingLevelPad) {
			this.properties.LoggingLevelPad := 1
		}
		if (not this.properties.PhraseEnthusiasm) {
			this.properties.PhraseEnthusiasm := 200
		}
	}
	
	saveProperties() {
		local
		fileHandle := FileOpen(this.propertiesFile, "w")
		header := "property,value`n"
		fileHandle.Write(header)
		
		for property, value in this.properties {
			propline := property "," value "`n"
			fileHandle.Write(propline)
		}
		
		fileHandle.Close()
	}
	
	saveStrokepaths() {
		local
		fileHandle := FileOpen(this.strokepathsFile, "w")
		header := "path=pattern`n"
		fileHandle.Write(header)
		
		for strokepathKey, garbage in this.strokepaths {
			strokepath := this.strokepaths.item(strokepathKey)
			pathline := strokepath.path "=" strokepath.pattern "`n"
			fileHandle.Write(pathline)
		}
		
		fileHandle.Close()
	}
   
	redactSenstiveQwerd(qwerd) {
		local
		if (RegexMatch(qwerd.qwerd, "^\d{2,}$")) {
			Return this.desensitizedQwerd
		}
		Return qwerd
	}
   
	redactSenstiveToken(token) {
		local
		if (RegexMatch(token, "^\d{2,}$")) {
			Return "****"
		}
		Return token
	}
   
	redactSenstiveInString(instring) {
		local
		outstring := RegexReplace(instring, "'[^' ]\d[^' ]+'", "'****'")
		Return outstring
	}
	
	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("qenv",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
