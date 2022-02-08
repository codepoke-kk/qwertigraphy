
Class Dashboarder {

	__New(engine) {
		this.title := "Dashboarder"
		this.name := "dashboarder"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Indicate(token) {
		this.logEvent(4, "Indicating " token.input)

		if (token.match) {
			token.ink := "blue"
		} else {
			token.ink := "red"
		}
        token.ticks := A_TickCount - token.created
        token.in_chars := StrLen(token.qwerd)
        token.out_chars := StrLen(token.word)
        token.wpm := (token.in_chars / (token.ticks / 12000))
        this.logEvent(4, "Speed of: " token.word " = ticks " token.ticks ", in " token.in_chars ", out " token.out_chars ", wpm " token.wpm)
        
		this.engine.dashboardQueue.enqueue(token)
		this.engine.speedQueue.enqueue(token)
		this.logEvent(4, "Enqueued dashboard qwerd " token.qwerd " with word " token.word " and form " token.form)
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