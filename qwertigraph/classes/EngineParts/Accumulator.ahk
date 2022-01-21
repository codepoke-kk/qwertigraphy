
Class Accumulator {

	__New(engine) {
		this.title := "Accumulator"
		this.name := "accumulator"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	AddKeyToToken(key) {
		this.logEvent(4, "Adding key " key " to token " this.engine.keyboard.Token)
		this.engine.keyboard.Token .= key
	}
	RemoveKeyFromToken() {
		this.logEvent(4, "Removing one character from token " this.engine.keyboard.Token)
		this.engine.keyboard.Token := SubStr(this.engine.keyboard.Token, 1, (StrLen(this.engine.keyboard.Token) - 1))
	}
	EndToken(key) {
		this.logEvent(4, "Key " key " ending token " this.engine.keyboard.Token)
		token := New TokenEvent(this.engine.keyboard.Token, key)
		this.engine.keyboard.Token := ""
		this.engine.NotifyEndToken(token)
	}
	CancelToken(key) {
		this.logEvent(4, "Key " key " cancelling token " this.engine.keyboard.Token)
		this.engine.keyboard.Token := ""
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