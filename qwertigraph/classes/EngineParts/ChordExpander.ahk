﻿
Class ChordExpander {

	__New(engine) {
		this.title := "ChordExpander"
		this.name := "chordexpander"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
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
			this.logEvent(2, "ChordWindow: completed")
			this.SendChord()
		} else {
			; Too slow. Let this be serial input
			this.logEvent(2, "Not a chord")
		}
		this.engine.keyboard.ChordPressStartTicks := 0
	}
	
	SendChord() {
		Critical
		; Send through a possible chord
		chord := this.engine.map.AlphaOrder(this.engine.keyboard.Token)
		if ((GetKeyState("Shift", "P")) or (GetKeyState("CapsLock", "T"))) {
			StringUpper, chord, chord
		}
		if (this.engine.map.chords.item(chord).word) {
			this.logEvent(4, "Chord " chord " found for " this.engine.map.chords.item(chord).word)
            if (Instr(this.engine.map.chords.item(chord).word, ")", , 0)) {
                this.logEvent(4, "Chord is for a script. Sending no End Character")
                ender := ""
            } else {
                ender := "{Space}"
            }
			token := New TokenEvent(this.engine.keyboard.Token, ender)
			token.input := chord
			token.qwerd := this.engine.map.chords.item(chord)
			token.output := token.qwerd.word
            token.method := "c"
			token.match := 1
			this.engine.keyboard.Token := ""
			this.engine.NotifyExpandedToken(token)
			this.engine.keyboard.AutoSpaceSent := ender 
			;this.ExpandInput(chord, "{Chord}", "", (A_TickCount - this.keyboard.TokenStartTicks))
			;if (not this.keyboard.ScriptCalled) {
			;	Send, {Space}
			;	; Mark that we sent this as a chord, so we know we need to send a backspace before the next end char
			;	this.keyboard.AutoSpaceSent := true
			;} 
		} else {
			this.logEvent(4, "Chord " chord " not found. Allow input to complete in serial fashion")
		}
		Critical Off 
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