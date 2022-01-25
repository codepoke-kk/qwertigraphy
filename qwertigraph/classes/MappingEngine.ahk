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
	
	NotifyEndToken(token) {
		this.logEvent(4, "Notified serial token ended by " token.ender " with " token.input)
		expanded_token := this.serialexpander.Expand(token)
		sent_token := this.sender.Send(expanded_token)
		coached_token := this.coacher.Coach(sent_token)
		dashboarded_token := this.dashboarder.Indicate(coached_token)
		this.recorder.Record(dashboarded_token)
		this.logEvent(4, "Completed handling of token #" this.record.MaxIndex())
	}
	
	NotifyChordedToken(token) {
		this.logEvent(4, "Notified chorded token ended by " token.ender " with " token.input)
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
	
	parseInbound(in_play_chars, end_char) {
		; Strategy: Reverse the chars, the first live characters are the token, then the first end char, and the preceding character 
		;	Make decisions based upon those 4 pieces of data
		inbound := {}
		inbound.final_end_char := end_char
		DllCall("msvcrt.dll\_wcsrev", "Ptr", &in_play_chars, "CDecl")
		finding_preceding_char := false 
		token := ""
		Loop, Parse, in_play_chars 
		{
			if (finding_preceding_char) {
				inbound.preceding_char := A_LoopField
				break
			}
			if (InStr("abcdefghijklmnopqrstuzwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", A_LoopField)) {
				; Not an end char, so add this to the token
				token .= A_LoopField
			} else {
				inbound.initial_end_char := A_LoopField
				finding_preceding_char := true 
			}
		}
		DllCall("msvcrt.dll\_wcsrev", "Ptr", &token, "CDecl")
		inbound.token := token
		
		;;; Decisions
		; Did we find anything to expand?
		inbound.hasToken := (StrLen(inbound.token) > 0)
		; Could this be a command line parameter like "-r"? 
		; Adding ";" to the check here makes :q not expand. That's important to a vim user like me. 
		inbound.isCode := (((inbound.preceding_char == " ") or (inbound.preceding_char == "")) and ((inbound.initial_end_char) and (InStr("-:;/", inbound.initial_end_char))))
		; Might this be a password?
        inbound.isSensitive := RegexMatch(inbound.token, "[0-9!@#$%\^&*<>?]")
		; Like "there's"
		inbound.isContraction := ((inbound.initial_end_char == "'") and (inbound.preceding_char) and (InStr(MappingEngine.ContractedEndings,inbound.token)))
		inbound.isAffix := false
		
		this.logEvent(4, "Inbound pre|end1|token|end2 |" inbound.preceding_char "|" inbound.initial_end_char "|" inbound.token "|" inbound.final_end_char "|")
		this.logEvent(4, "hasToken = " inbound.hasToken ", and isCode = " inbound.isCode ", and isSensitive = " inbound.isSensitive ", and isContraction = " inbound.isContraction)
		return inbound
	}
	
	pushInput(qwerd, word, end_key) {
		
		;;; Expand the qwerd into its word 
		this.logEvent(1, "Pushing " qwerd " to " word end_key)
		final_characters_count := StrLen(word) + 1
		; expand this qwerd by first deleting the qwerd itself and its end character if not suppressed
		deleteChars := StrLen(qwerd)
		if (not this.keyboard.AutoSpaceSent) {
			;deleteChars++
		}
		this.logEvent(4, "Sending " deleteChars " backspaces")
		Send, {Backspace %deleteChars%}
		
		;;; Identify script calls and launch them from here
		if (Instr(word, ")", , 0)) {
			this.logEvent(2, "Scripting " word " from " qwerd " ending with " end_key)
			function_name := Substr(word, 1, Instr(word, "(") - 1)
			this.logEvent(4, "Function name is " function_name)
			fn := Func(function_name)
			this.logEvent(4, "Function is " fn.Name)
			fn.Call(qwerd, word, end_key)
			this.logEvent(4, "Call complete")
			this.keyboard.ScriptCalled := true
		} else {
			this.logEvent(4, "Sending '" word "'")
			; Msgbox, % "Hold"
			Send, % word
			;;; Expand the qwerd into the buffer as well 
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - (StrLen(qwerd)))) word
		}
		
		this.logEvent(4, "Buffer after expansion is '" this.input_text_buffer "'")
		
		return final_characters_count
	}
	
	pushCoaching(qwerd, match, miss, other, key, chorded) {
		coaching := new CoachingEvent()
		coaching.word := qwerd.word
		coaching.qwerd := qwerd.qwerd
		coaching.chord := qwerd.chord
		coaching.chordable := qwerd.chordable
		coaching.chorded := chorded
		coaching.form := qwerd.form
		coaching.saves := qwerd.saves
		coaching.power := qwerd.power
		coaching.match := match
		coaching.cmatch := chorded
		coaching.miss := miss
		coaching.other := other
		coaching.endKey := key
		this.coachQueue.enqueue(coaching)
		this.logEvent(3, "Enqueued coaching " coaching.word " (" coaching.chord "," coaching.chordable ")")
		
		if (miss) { 
			this.flashTip(coaching)
		}
	}
		
	pushDashboardQwerd(qwerd, ink) {
		dashboardQwerd := new DashboardEvent(qwerd.form, qwerd.qwerd, qwerd.word, ink)
		this.dashboardQueue.enqueue(dashboardQwerd)
		this.logEvent(3, "Enqueued dashboard action '" dashboardQwerd.form "'")
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
