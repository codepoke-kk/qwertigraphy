
class QwertigraphyEnvironment
{
	personalizedFiles := {"templates\personal.template":"personal.csv", "templates\dictionary_load.template":"dictionary_load.list", "templates\negations.template":"negations.txt", "templates\retrains.template":"retrains.txt", "templates\personal_functions.template":"personal_functions.ahk", "templates\qwertigraph.template":"qwertigraph.properties"}
	personalDataFolder := A_AppData "\Qwertigraph"
	dictionaryListFile := this.personalDataFolder "\dictionary_load.list"
	negationsFile := this.personalDataFolder "\negations.txt"
	retrainsFile := this.personalDataFolder "\retrains.txt"
	propertiesFile := this.personalDataFolder "\qwertigraph.properties"
	properties := {}
	
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
	
	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("qenv",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
