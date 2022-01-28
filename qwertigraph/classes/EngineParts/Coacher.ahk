
Class Coacher {

	__New(engine) {
		this.title := "Coacher"
		this.name := "coacher"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Coach(token) {
        if ((not token.output) and (this.engine.map.hints.item(token.input).word)) {
            this.logEvent(4, "Coaching " this.engine.map.hints.item(token.input).word " as " token.input)
            token.qwerd := this.engine.map.hints.item(token.input).qwerd
            token.word := this.engine.map.hints.item(token.input).word
            token.form := this.engine.map.hints.item(token.input).form
        } else {
            token.form := token.qwerdobject.form
            token.qwerd := token.qwerdobject.qwerd
            token.word := token.qwerdobject.word
            this.logEvent(4, "Coaching for " token.output " as " token.word)
        }
        token.chordable := token.qwerdobject.chordable
        token.saves := token.qwerdobject.saves
        token.power := token.qwerdobject.power
		this.engine.coachQueue.enqueue(token)
		this.logEvent(4, "Enqueued coaching " token.word " (" token.chord ")")
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