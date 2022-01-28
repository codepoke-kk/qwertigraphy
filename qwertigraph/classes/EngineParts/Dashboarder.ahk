
Class Dashboarder {

	__New(engine) {
		this.title := "Dashboarder"
		this.name := "dashboarder"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Indicate(token) {
		this.logEvent(4, "Indicating " token.input)
		
		token.form := token.qwerdobject.form
		token.qwerd := token.qwerdobject.qwerd
		token.word := token.qwerdobject.word
		if (token.match) {
			token.ink := "blue"
		} else {
			token.ink := "red"
		}
		
		this.engine.dashboardQueue.enqueue(token)
		this.logEvent(4, "Enqueued dashboard action '" token.form "'")
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