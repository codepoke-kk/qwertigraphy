
Class Sender {

	__New(engine) {
		this.title := "Sender"
		this.name := "sender"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Send(token) {
		this.logEvent(4, "Sending " token.input " as " token.output)
		
		if (not StrLen(token.output)) {
			this.logEvent(4, "Token input " token.input " unmatched")
			token.active_edited := false 
			Send, % token.ender
			return token
		} else if (token.input == token.output) {
			this.logEvent(4, "Token input " token.input " matched output")
			token.active_edited := false 
			Send, % token.ender
			return token
		} else {
			token.active_edited := true 
			token.deleted_characters := StrLen(token.input)
			this.logEvent(4, "Sending " token.deleted_characters " backspaces")
			Send, % "{Backspace " token.deleted_characters "}"
			this.logEvent(4, "Sending " token.output)
			Send, % token.output
			this.logEvent(4, "Sending " token.ender)
			Send, % token.ender
			return token
		}
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