
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
		this.logEvent(4, "Recording " token.input)
		this.engine.record.Push(token)
	}

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent(this.name,A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}