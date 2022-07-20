
Class Accumulator {

	__New(engine) {
		this.title := "Accumulator"
		this.name := "accumulator"
		this.engine := engine
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
        this.starttime := 0
        this.retrievedTokenIndex := 0
        this.retrievedTokenHorizon := 0
        this.retrievedEnder := 0

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
            this.retrievedTokenIndex := 0
            this.retrievedEnder := 0
			this.logEvent(4, "Ctrl-Backspace clears token")
		} else if (StrLen(this.engine.keyboard.Token)) {
			this.engine.keyboard.Token := SubStr(this.engine.keyboard.Token, 1, (StrLen(this.engine.keyboard.Token) - 1))
		} else {
            ; Not simple.
            ; This process allows us to walk back a long way into the buffer as the user backspaces across several words
            ; I may need to fix a problem where a user backspaces maybe 4 words, types 1, then backspaces 2 more. Right now that fails
            this.logEvent(4, "Backspacing into buffer from position " this.retrievedTokenIndex)
            if (not this.retrievedTokenIndex) {
                this.logEvent(4, "Have no retrieved token - taking the last one at " this.engine.record.MaxIndex())
                this.retrievedTokenIndex := this.engine.record.MaxIndex()
                this.retrievedEnder := 0
                bufferToken := this.engine.record[this.retrievedTokenIndex]
                bufferWord := bufferToken.output ? bufferToken.output : bufferToken.input
            } else {
                if (not this.retrievedEnder) {
                    this.retrievedEnder := 1
                    this.logEvent(4, "Have retrieved token, but have not retrieved ender - taking dummy token")
                    bufferWord := ""
                } else {
                    if (this.retrievedTokenIndex > this.retrievedTokenHorizon) {
                        this.retrievedTokenIndex -= 1
                        bufferToken := this.engine.record[this.retrievedTokenIndex]
                        bufferWord := bufferToken.output ? bufferToken.output : bufferToken.input
                        if (this.retrievedTokenIndex == (this.engine.record.MaxIndex() - 1)) {
                            bufferWord := SubStr(bufferWord, 1, (StrLen(bufferWord) - 1))
                        }
                        this.logEvent(4, "Have already retrieved ender - taking previous token at " this.retrievedTokenIndex)
                    } else {
                        this.logEvent(4, "Have already retrieved all tokens back to token horizon")
                        bufferWord := ""
                    }
                }
            }
            this.engine.keyboard.Token := bufferWord
			this.logEvent(4, "No characters to remove, reloading token #" this.retrievedTokenIndex " output as: " this.engine.keyboard.Token)
		}
	}
	EndToken(key) {
        if ((GetKeyState("Shift")) and (InStr(";", key))) {
			this.logEvent(2, "Key " key " is actually a colon")
			key := ":"
		}
		this.logEvent(4, "Key " key " ending token " this.engine.keyboard.Token)
		token := New TokenEvent(this.engine.keyboard.Token, key)
        token.created := this.starttime
        token.method := "s"
        this.starttime := A_TickCount
		this.engine.keyboard.Token := ""
        this.retrievedTokenIndex := 0
        this.retrievedEnder := 0
        if ((key != "{Space}") and (not InStr(",.;:'""", key))) {
            this.retrievedTokenHorizon := this.engine.record.MaxIndex() + 2
            this.logEvent(4, "Set token retrieval token horizon to " this.retrievedTokenHorizon)
        }
		this.engine.NotifySerialToken(token)
	}
	CancelToken(key) {
		this.logEvent(4, "Key " key " cancel token " this.engine.keyboard.Token " and set horizon to " this.engine.record.MaxIndex() + 2)
		this.engine.keyboard.Token := ""
        this.retrievedTokenIndex := 0
        this.retrievedEnder := 0
        this.retrievedTokenHorizon := this.engine.record.MaxIndex() + 2
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