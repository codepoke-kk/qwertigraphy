
Class ChordExpander {

	__New(engine) {
		this.title := "ChordExpander"
		this.name := "chordexpander"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	LeaveChord(key) {
		if (not this.engine.keyboard.ChordPressStartTicks) {
			this.logEvent(4, "No chord started. Leaving")
			return 
		}
		chordWindow := A_TickCount - this.engine.keyboard.ChordPressStartTicks
		this.logEvent(4, "Evaluating chord of length " StrLen(this.engine.keyboard.Token) " after release of " key " in " chordWindow "ms against window of " this.engine.keyboard.ChordReleaseWindows[StrLen(this.engine.keyboard.Token)] "ms")
		if ((StrLen(this.engine.keyboard.Token) >= this.engine.keyboard.ChordMinimumLength) 
			and (chordWindow > 0) 
			and (chordWindow < this.engine.keyboard.ChordReleaseWindows[StrLen(this.engine.keyboard.Token)])) {
			; The time is quick enough to call a chord 
			this.logEvent(2, "ChordWindow: completed with " this.engine.keyboard.Token)
			this.SendChord()
		} else {
			; Too slow. Let this be serial input
			this.logEvent(2, "Not a chord")
		}
		this.engine.keyboard.ChordPressStartTicks := 0
	}
	
	SendChord() {
		; Send through a possible chord
		chord := this.engine.map.AlphaOrder(this.engine.keyboard.Token)
        this.logEvent(2, "Have possible chord " chord)
		if ((GetKeyState("Shift", "P")) or (GetKeyState("CapsLock", "T")) or (SubStr(this.engine.map.chords.item(chord).word, 1, 2) = "i ")) {
			StringUpper, chord, chord
			this.logEvent(2, "Uppercased chord to " chord)
		}
		if (this.engine.map.chords.item(chord).word) {
			this.logEvent(3, "Chord " chord " found for " this.engine.map.chords.item(chord).word)
            if (Instr(this.engine.map.chords.item(chord).word, ")", , 0)) {
                this.logEvent(4, "Chord is for a script. Sending no End Character")
                ender := ""
            } else {
                ender := "{Space}"
            }
			token := New TokenEvent(this.engine.keyboard.Token, ender)
			token.input := chord
			token.qwerdobject := this.engine.map.chords.item(chord)
			token.output := token.qwerdobject.word
            token.method := "c"
			token.match := 1
            token.chorded := 1
			this.engine.keyboard.Token := ""
			this.engine.NotifyExpandedToken(token)
			this.engine.keyboard.AutoSpaceSent := ender 
		} else {
			this.logEvent(3, "Chord " chord " not found. Allow input to complete in serial fashion")
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