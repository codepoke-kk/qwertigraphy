
Class Recorder {

	__New(engine) {
		this.title := "Recorder"
		this.name := "recorder"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Record(token) {
        token.index := this.engine.record.MaxIndex() + 1
		this.engine.record.Push(token)
		this.logEvent("R", token.index "()," token.input "," token.output "," token.method ",-" token.deleted_characters)
	}

	LogEvent(verbosity, message) 
	{
        event := new LoggingEvent(this.name,A_Now,message,verbosity)
        this.logQueue.enqueue(event)
	}
}