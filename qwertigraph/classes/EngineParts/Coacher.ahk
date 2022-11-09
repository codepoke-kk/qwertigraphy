
Class Coacher {

	__New(engine) {
		this.title := "Coacher"
		this.name := "coacher"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Coach(token) {
        if (not token.output) {
            if (this.engine.map.hints.item(token.input).word) {
                this.logEvent(4, "Coaching missed " this.engine.map.hints.item(token.input).word " as " token.input " and chord " this.engine.map.hints.item(token.input).chord)
                token.qwerd := this.engine.map.hints.item(token.input).qwerd
                token.word := this.engine.map.hints.item(token.input).word
                token.form := this.engine.map.hints.item(token.input).form
				token.chord := this.engine.map.hints.item(token.input).chord
            } else {
                this.logEvent(4, "Unknown and uncoachable " token.input " and chord " token.qwerdobject.chord) 
                token.form := token.qwerdobject.form
                token.qwerd := token.qwerdobject.qwerd
                token.word := token.qwerdobject.word
				token.chord := token.qwerdobject.chord
                token.other := 1
            }
        } else {
            token.form := token.qwerdobject.form
            token.qwerd := token.qwerdobject.qwerd
            token.word := token.qwerdobject.word
			token.chord := token.qwerdobject.chord
            this.logEvent(4, "Coaching hit " token.output " as " token.word " and chord " token.qwerdobject.chord)
        }
        token.chordable := token.qwerdobject.chordable
        token.saves := token.qwerdobject.saves
        token.power := token.qwerdobject.power
        token.cmatch := token.chorded
		this.engine.coachQueue.enqueue(token)
		this.logEvent(4, "Enqueued coaching " token.word " (" token.chord ")")
		return token
	}
	
	CoachAhead(accumulated) {
		this.logEvent(4, "Coaching ahead " accumulated)
		if (StrLen(accumulated) < 1) {
			this.logEvent(4, "Bailing due to short in string (" accumulated ")")
			return
		}
		
		in_chars := this.engine.map.qenv.redactSenstiveToken(accumulated)
		this.presentGraphicalCoachingAhead(in_chars)
		this.presentTextualCoachingAhead(in_chars)
		; this.engine.dashboard.visualizeQueue()
	}
	
	presentGraphicalCoachingAhead(in_chars) {
		this.logEvent(4, "Graphical coaching ahead on " in_chars)
		; Is this token a word 
		coachAheadQwerd := new TokenEvent(in_chars, "")
		coachAheadQwerd.ink := "white"
		if (this.engine.map.qwerds.item(in_chars).qwerd) {
			this.logEvent(4, "Found coach ahead match for " this.engine.map.qwerds.item(in_chars).qwerd)
            coachAheadQwerd.qwerd := this.engine.map.qwerds.item(in_chars).qwerd
			coachAheadQwerd.word := this.engine.map.qwerds.item(in_chars).word
			coachAheadQwerd.form := this.engine.map.qwerds.item(in_chars).form
			coachAheadQwerd.chord := this.engine.map.qwerds.item(in_chars).chord
		} else if (this.engine.map.hints.item(in_chars).word) {
			this.logEvent(4, "Found coach ahead hint for " this.engine.map.hints.item(in_chars).word)
            coachAheadQwerd.qwerd := this.engine.map.hints.item(in_chars).qwerd
			coachAheadQwerd.word := this.engine.map.hints.item(in_chars).word
			coachAheadQwerd.form := this.engine.map.hints.item(in_chars).form
			coachAheadQwerd.chord := this.engine.map.hints.item(in_chars).chord
		} else {
			this.logEvent(4, "No found coach ahead")
            coachAheadQwerd.qwerd := in_chars
			coachAheadQwerd.word := in_chars
			coachAheadQwerd.form := "--"
			coachAheadQwerd.chord := "--"
		}
		this.logEvent(4, "Replacing existing coach ahead qwerd " this.engine.dashboard.coachAheadQwerd.word " with " coachAheadQwerd.qwerd)
		this.engine.dashboard.coachAheadQwerd := coachAheadQwerd
	}

	presentTextualCoachingAhead(in_chars) {
		; Is this token a word 
		if (this.engine.map.qwerds.item(in_chars).word) {
			coachAheadWord := this.engine.map.qwerds.item(in_chars).word
		} else {
			coachAheadWord := "--"
		}
		this.logEvent(4, "Coachahead word is " coachAheadWord)
		coachAheadNote := ""
		For letter_index, letter in ["u", "i", "o", ""]
		{
			; Show the whole qwerd as the last coach ahead hint in this line. That requires some adjustment. 
			printLetter := (StrLen(letter)) ? letter : in_chars 
			printWord := Substr(this.engine.map.qwerds.item(in_chars . letter).word, 1, (11 - StrLen(printLetter)))
			if (this.engine.map.qwerds.item(in_chars . letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", printLetter, this.engine.map.qwerds.item(in_chars . letter).reliability, printWord)
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			} else {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", printLetter, " ", "")
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			}
			coachAheadNote .= coachAheadPhrase
		}
		coachAheadNote .= "`n"
		For letter_index, letter in ["e", "a", "d", "t"]
		{
			if (this.engine.map.qwerds.item(in_chars . letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, this.engine.map.qwerds.item(in_chars . letter).reliability, Substr(this.engine.map.qwerds.item(in_chars . letter).word, 1, 10))
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			} else {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, " ", "")
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			}
			coachAheadNote .= coachAheadPhrase
		}
		coachAheadNote .= "`n"
		For letter_index, letter in ["s", "g", "n", "r"]
		{
			if (this.engine.map.qwerds.item(in_chars . letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, this.engine.map.qwerds.item(in_chars . letter).reliability, Substr(this.engine.map.qwerds.item(in_chars . letter).word, 1, 10))
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			} else {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, " ", "")
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			}
			coachAheadNote .= coachAheadPhrase
		}
		this.logEvent(4, "Coachahead note " coachAheadNote)
		
		this.engine.dashboard.coachAheadHints := coachAheadNote
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