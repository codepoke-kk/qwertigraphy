
Class Accumulator {

	__New(engine) {
		this.title := "Accumulator"
		this.name := "accumulator"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
        this.starttime := 0
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	AddKeyToToken(key) {
		this.logEvent(4, "Adding key " key " to token " this.engine.keyboard.Token)
		if ((GetKeyState("Shift", "P")) or (GetKeyState("CapsLock", "T"))) {
			this.logEvent(4, "Uppercasing " key)
			StringUpper key, key
		} 
        if (not this.engine.keyboard.Token) {
            if ((not this.starttime) or (this.starttime < (A_TickCount - 1000))) {
                ; Set the start time or reset it if it's been more than 1 second since last entry
                this.starttime := A_TickCount
            }
        }
		this.engine.keyboard.Token .= key
		this.engine.coacher.CoachAhead(this.engine.keyboard.Token)
	}
	RemoveKeyFromToken() {
		this.logEvent(4, "Removing one character from token " this.engine.keyboard.Token)
		if (GetKeyState("Control", "P")) {
			this.engine.keyboard.Token := "" 
			this.logEvent(4, "Ctrl-Backspace clears token")
		} else if (StrLen(this.engine.keyboard.Token)) {
			this.engine.keyboard.Token := SubStr(this.engine.keyboard.Token, 1, (StrLen(this.engine.keyboard.Token) - 1))
		} else {
			bufferToken := this.engine.record[this.engine.record.MaxIndex()]
			bufferWord := bufferToken.output ? bufferToken.output : bufferToken.input 
			this.engine.keyboard.Token := bufferWord 
			this.logEvent(4, "No characters to remove, reloading previous token output as: " this.engine.keyboard.Token)
		}
	}
	EndToken(key) {
		this.logEvent(4, "Key " key " ending token " this.engine.keyboard.Token)
		token := New TokenEvent(this.engine.keyboard.Token, key)
        token.created := this.starttime
        token.method := "s"
        this.starttime := A_TickCount
		this.engine.keyboard.Token := ""
		this.engine.NotifySerialToken(token)
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