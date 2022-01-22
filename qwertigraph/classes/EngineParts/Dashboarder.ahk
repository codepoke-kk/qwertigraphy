
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
		if (token.match) {
			ink := "blue"
		} else {
			ink := "red"
		}
		dashboardQwerd := new DashboardEvent(token.qwerd.form, token.qwerd.qwerd, token.qwerd.word, ink)
		this.engine.dashboardQueue.enqueue(dashboardQwerd)
		this.logEvent(4, "Enqueued dashboard action '" dashboardQwerd.form "'")
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