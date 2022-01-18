
Class ChordSender {

	__New(engine) {
		this.title := "ChordSender"
		this.name := "chordsender"
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