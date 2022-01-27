/*
- Edge cases to remember when testing 
Alt-tab must work 
Shifted number keys must work 
Shifted symbol keys must work 
Mask passwords in logs
Control+letter must cancel its own token
*/

#InstallKeybdHook
engine := {}

#Include %A_AppData%\Qwertigraph\personal_functions.ahk
#Include scripts\default.ahk

#Include classes\EngineParts\Keyboard.ahk
#Include classes\EngineParts\Listener.ahk
#Include classes\EngineParts\Accumulator.ahk
#Include classes\EngineParts\TokenEvent.ahk
#Include classes\EngineParts\SerialExpander.ahk
#Include classes\EngineParts\ChordExpander.ahk
#Include classes\EngineParts\Sender.ahk
#Include classes\EngineParts\Coacher.ahk
#Include classes\EngineParts\Dashboarder.ahk
#Include classes\EngineParts\Recorder.ahk

class MappingEngine {
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	
	map := ""
	dashboard := ""
	last_end_key := ""
	characters_typed_raw := ""
	characters_typed_final := ""
	time_taken := ""
	average_raw_wpm := ""
	average_final_wpm := ""
	discard_ratio := ""
	input_text_buffer := ""
	logQueue := new Queue("EngineQueue")
	logVerbosity := 4
	tip_power_threshold := 1
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")
	dashboardQueue := new Queue("DashboardQueue")
	
	nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

	__New(map, aux)	{
		this.map := map
		this.aux := aux
		
		this.keyboard := New Keyboard(this)
		this.listener := New Listener(this)
		this.accumulator := New Accumulator(this)
		this.serialexpander := New SerialExpander(this)
		this.chordexpander := New ChordExpander(this)
		this.sender := New Sender(this)
		this.coacher := New Coacher(this)
		this.dashboarder := New Dashboarder(this)
		this.recorder := New Recorder(this)
		this.record := []
		
	}
		
	Start() {
		this.listener.Start(this.accumulator)
	}	 
	Stop() 	{
		this.listener.Stop(this.accumulator)
	}
	
	NotifySerialToken(token) {
        ; Called by the Accumulator upon EndToken
		this.logEvent(4, "Notified serial token ended by " token.ender " with " token.input)
		expanded_token := this.serialexpander.Expand(token)
		this.NotifyExpandedToken(expanded_token)
		;sent_token := this.sender.Send(expanded_token)
		;coached_token := this.coacher.Coach(sent_token)
		;dashboarded_token := this.dashboarder.Indicate(coached_token)
		;this.recorder.Record(dashboarded_token)
		;this.logEvent(4, "Completed handling of token #" this.record.MaxIndex())
	}
	
	NotifyExpandedToken(token) {
        ; Called by the ChordExpander upon SendChord
		this.logEvent(4, "Notified expanded token ended by " token.ender " with " token.input)
		sent_token := this.sender.Send(token)
		coached_token := this.coacher.Coach(sent_token)
		dashboarded_token := this.dashboarder.Indicate(coached_token)
		this.recorder.Record(dashboarded_token)
		this.logEvent(4, "Completed handling of token #" this.record.MaxIndex())
	}
	
	ResetInput() {
		this.logEvent(2, "Input reset by function ")
		this.listener.CancelToken("{LButton}")
	}
	
	getInPlayChars(buffer) {
		if (StrLen(buffer) > (this.map.longestQwerd + 1)) {
			in_play_chars := SubStr(buffer, (StrLen(buffer) - (this.map.longestQwerd + 1)))
		} else {
			in_play_chars := buffer
		}
		this.logEvent(4, "In play chars are '" in_play_chars "'")
        
		return in_play_chars
	}
	
	coachAhead(start) {
		global engine
		if (start) {
			SetTimer, DoPresentCoachingAhead, % (-1 * this.keyboard.CoachAheadWait)
		} else {
			SetTimer, DoPresentCoachingAhead, Off
		}
		return 

		DoPresentCoachingAhead:
		  engine.presentCoachingAhead()
		return 
	}
	
	presentCoachingAhead() {
		global engine 
		token := this.map.qenv.redactSenstiveToken(this.keyboard.token)
		this.presentGraphicalCoachingAhead(token)
		this.presentTextualCoachingAhead(token)
		engine.dashboard.visualizeQueue()
	}

	presentGraphicalCoachingAhead(token) {
		global engine
		this.logEvent(2, "Graphical coaching ahead on " token)
		if (StrLen(token) < 1) {
			this.logEvent(4, "Bailing due to short token (" token ")")
			return
		}
		; Is this token a word 
		coachAheadQwerd := ""
		if (this.map.qwerds.item(token).qwerd) {
			this.logEvent(4, "Found coach ahead for " this.map.qwerds.item(token).qwerd)
			coachAheadQwerd := new DashboardEvent(this.map.qwerds.item(token).form, token, this.map.qwerds.item(token).word, "green")
		} else if (this.map.hints.item(token).word) {
			this.logEvent(4, "Found coach ahead for " this.map.hints.item(token).word)
			coachAheadQwerd := new DashboardEvent(this.map.hints.item(token).form, this.map.hints.item(token).qwerd, this.map.hints.item(token).word, "green")
		} else {
			this.logEvent(4, "No found coach ahead")
			coachAheadQwerd := new DashboardEvent(token, token, "--", "green")
		}
		engine.dashboard.coachAheadQwerd := coachAheadQwerd
		this.logEvent(4, "Replacing existing coach ahead qwerd " this.dashboard.coachAheadQwerd.word " with " coachAheadQwerd.qwerd)
	}

	presentTextualCoachingAhead(token) {
		global engine
		this.logEvent(4, "Textual coaching ahead on " token)
		if (StrLen(token) < 1) {
			this.logEvent(4, "Bailing due to short token (" token ")")
			return
		}
		; Is this token a word 
		if (this.map.qwerds.item(token).word) {
			coachAheadWord := this.map.qwerds.item(token).word
		} else {
			coachAheadWord := "--"
		}
		this.logEvent(4, "Coachahead word is " coachAheadWord)
		coachAheadNote := ""
		For letter_index, letter in ["u", "i", "o", ""]
		{
			; Show the whole qwerd as the last coach ahead hint in this line. That requires some adjustment. 
			printLetter := (StrLen(letter)) ? letter : token 
			printWord := Substr(this.map.qwerds.item(token letter).word, 1, (11 - StrLen(printLetter)))
			if (this.map.qwerds.item(token letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", printLetter, this.map.qwerds.item(token letter).reliability, printWord)
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
			if (this.map.qwerds.item(token letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, this.map.qwerds.item(token letter).reliability, Substr(this.map.qwerds.item(token letter).word, 1, 10))
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
			if (this.map.qwerds.item(token letter).word) {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, this.map.qwerds.item(token letter).reliability, Substr(this.map.qwerds.item(token letter).word, 1, 10))
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			} else {
				coachAheadPhrase := Format("{:2} {:1}= {:-10}", letter, " ", "")
				this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
			}
			coachAheadNote .= coachAheadPhrase
		}
		this.logEvent(2, "Coachahead note " coachAheadNote)
		
		engine.dashboard.coachAheadHints := coachAheadNote
	}
	
	flashTip(coachEvent) {
		if (coachEvent.power < this.tip_power_threshold) {
			return
		}
		CoordMode, ToolTip, Relative
		; MsgBox, % "flashing engine " coachEvent.qwerd " as " this.map.qwerds.item(coachEvent.qwerd).dictionary " and got " this.map.qwerds.item(coachEvent.qwerd).reliability
		if (coachEvent.chordable = "active") {
			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd " (" coachEvent.chord ")" coachEvent.note, 0, 0 ; A_CaretX, A_CaretY + 30
		} else {
			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd coachEvent.note, 0, 0 ; A_CaretX, A_CaretY + 30
		}
		SetTimer, ClearToolTipEngine, % (-1 * this.keyboard.CoachAheadTipDuration)
		return 

		ClearToolTipEngine:
		  ToolTip
		return 
	}
    
    setKeyboardChordWindowIncrements() {
        
        increment := Round(this.keyboard.ChordReleaseWindow / 3)
        Loop, 26 {
            this.keyboard.ChordReleaseWindows[A_Index] := A_Index * increment
        }
    }

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("engine",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
