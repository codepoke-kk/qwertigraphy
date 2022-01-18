
Class Expander {

	__New(engine) {
		this.title := "Expander"
		this.name := "expander"
		this.engine := engine 
		this.logQueue := new Queue("Engine" this.title "Queue")
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
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