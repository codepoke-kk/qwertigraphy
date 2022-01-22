
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
		this.logEvent(4, "Coaching " token.input " as " token.output)
		coaching := new CoachingEvent()
		coaching.word := token.qwerd.word
		coaching.qwerd := token.qwerd.qwerd
		coaching.chord := token.qwerd.chord
		coaching.chordable := token.qwerd.chordable
		coaching.chorded := token.chorded
		coaching.form := token.qwerd.form
		coaching.saves := token.qwerd.saves
		coaching.power := token.qwerd.power
		coaching.match := token.match
		coaching.cmatch := token.chorded
		coaching.miss := token.miss
		coaching.other := token.other
		coaching.endKey := token.ender
		this.engine.coachQueue.enqueue(coaching)
		this.logEvent(4, "Enqueued coaching " coaching.word " (" coaching.chord "," coaching.chordable ")")
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