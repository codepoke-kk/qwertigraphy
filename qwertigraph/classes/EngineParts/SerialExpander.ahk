
Class SerialExpander {

	__New(engine) {
		this.title := "SerialExpander"
		this.name := "serialexpander"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Expand(token) {
		this.logEvent(4, "Expanding after " token.ender " with " token.input)
		if (this.engine.map.qwerds.item(token.input).word) {
			token.qwerd := this.engine.map.qwerds.item(token.input)
			token.output := token.qwerd.word
			token.match := 1
		} else {
			this.nullQwerd.word := token.input
			this.nullQwerd.qwerd := token.input
			token.qwerd := this.nullQwerd
			token.miss := 1
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