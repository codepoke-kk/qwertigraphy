
Class SerialExpander {

	__New(engine) {
		this.title := "SerialExpander"
		this.name := "serialexpander"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Expand(token) {
		this.logEvent(4, "Expanding after " token.ender " with " token.input)
		if (this.engine.map.qwerds.item(token.input).word) {
			token.output := this.engine.map.qwerds.item(token.input).word
		}
		this.logEvent(4, token.input " -> " token.output)
		return token
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