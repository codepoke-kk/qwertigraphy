engine := {}

class MappingEngine_InputHook
{
	Static MovementKeys := "{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}"
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	Static EndKeys_soft := "{LControl}{RControl}{backspace}{enter}{tab}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}{LButton}"
	Static EndKeys_hard := " .,?!;:'""-_{{}{}}[]/+=|()@#$%^&*<>"
	Static EndKeys := MappingEngine_InputHook.EndKeys_soft MappingEngine_InputHook.EndKeys_hard
	
	map := ""
	ih := ""
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
	tip_power_threshold := 2
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")

	__New(map)
	{
		this.map := map
	}
		
	Start() 
	{
		loop
		{
			this.ih := InputHook("VCE", MappingEngine_InputHook.EndKeys)
			; Don't allow Enter and Tab to go through, or those keys will exit a field before expanding the text
			this.ih.KeyOpt("{Enter}{Tab}", "+S")
			;Msgbox, % "Backspace is " ih.BackspaceIsUndo
			this.ih.Start()
			input_start := A_TickCount
			ErrorLevel := this.ih.Wait()
			if (ErrorLevel = "EndKey") {
				; Only react when the input is collected due to a stop key being pressed
				if (not InStr(MappingEngine_InputHook.MovementKeys, this.ih.EndKey)) {
					; Only react when the input is collected due to a non-movement key
					ErrorLevel .= ":" this.ih.EndKey
					this.ExpandInput(this.ih.Input, this.ih.EndKey, this.ih.EndMods, (A_TickCount - input_start))
				}
			} 
		}
	}	 
	 
	ExpandInput(input_text, key, mods, ticks) {

		; First glue this input to the buffer 
		this.logEvent(2, "Expanding '" input_text "' ended with '" key "' after " ticks " millis")
	    this.input_text_buffer := this.input_text_buffer . input_text
		this.logEvent(4, "Input_text after buffering '" this.input_text_buffer "'")
		
		; Suppressing Enter and Tab, to keep them from messing up field inputs. We'll have to send them every time
		must_send_endkey := (InStr("EnterTab", key) > 0)
		this.logEvent(4, "Must send end key is " must_send_endkey)
		
		; if ((input_text) or (key = "Backspace")) {
		if (True) {
			if (StrLen(this.input_text_buffer) > (this.map.longestQwerd + 1)) {
				in_play_chars := SubStr(this.input_text_buffer, (StrLen(this.input_text_buffer) - (this.map.longestQwerd + 1)))
			} else {
				in_play_chars := this.input_text_buffer
			}
		} else {
			this.logEvent(4, "No input text and key is '" key "', so no in play chars")
			in_play_chars := ""
		}
		this.logEvent(4, "In play chars are '" in_play_chars "'")
		token := ""
		end_char := ""
		embedded_end_char := ""
		leading_end_char := False
		Loop, Parse, in_play_chars 
		{
			this.logEvent(4, "Playing " A_LoopField " with " token "/" embedded_end_char "/" end_char "/" leading_end_char)
			if (InStr("abcdefghijklmnopqrstuzwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", A_LoopField)) {
				if (end_char) {
					token := ""
					embedded_end_char := end_char
					end_char := ""
				}
				token .= A_LoopField
			} else {
				if ((not end_char) or (end_char = " ")) {
					leading_end_char := True
				}
				end_char := A_LoopField
			}
		}
		this.logEvent(3, "Token '" token "', embedded end char '" embedded_end_char "', end char '" end_char "', and leading end char " leading_end_char)
		
		;;; Now handle the token itself 
		if (key = "Backspace") {
			this.logEvent(4, "Handling backspace")
			final_characters_count := -1
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1))
		} else if (key == "LControl" or key == "RControl") {
			; The control key kills an input without expansion
			final_characters_count := StrLen(token) + 1
			this.logEvent(3, "Cancelled via control key " token)
		} else if ((embedded_end_char == "'") and (InStr(MappingEngine_InputHook.ContractedEndings,token))) {
			this.logEvent(4, "Handling apostrophe")
			; If the last input ended with ' and this input is a common contraction
			Switch token
			{
				Case "r":
					this.logEvent(4, "Handling 'r")
					Send, {Backspace}e
					Send, % key
					this.input_text_buffer .= "e" end_char
					final_characters_count := 3
				Case "v":
					this.logEvent(4, "Handling 'v")
					Send, {Backspace}e
					Send, % key
					this.input_text_buffer .= "e" end_char
					final_characters_count := 3
				Case "l":
					this.logEvent(4, "Handling 'l")
					Send, {Backspace}l
					Send, % key
					this.input_text_buffer .= "l" end_char
					final_characters_count := 3
				Default:
					this.logEvent(4, "Handling all others")
					final_characters_count := StrLen(token) + 1
			}
			this.logEvent(3, "Completed contraction " token)
		} else if ((embedded_end_char == "-") and (leading_end_char)) {
			this.logEvent(4, "Handling leading hyphen")
			; If the last input began with -
			final_characters_count := StrLen(token) + 1
			this.logEvent(3, "Completed contraction " token)
		} else if (this.map.qwerds.item(token).word) {
			if (not InStr(mods, "^")) {
				; Success 
				; Coach the found qwerd
				coaching := new CoachingEvent()
				coaching.word := this.map.qwerds.item(token).word
				coaching.qwerd := token
				coaching.form := this.map.qwerds.item(token).form
				coaching.saves := this.map.qwerds.item(token).saves
				coaching.power := this.map.qwerds.item(token).power
				coaching.match := true
				coaching.endKey := key
				this.coachQueue.enqueue(coaching)
				this.logEvent(3, "Enqueued success coaching " coaching.word)
				
				; Add this qwerd to the GreggPad display
				penAction := new PenEvent(this.map.qwerds.item(token).form, token, this.map.qwerds.item(token).word)
				this.penQueue.enqueue(penAction)
				this.logEvent(4, "Enqueued pen action '" penAction.form "'")
				
				;;; Expand the qwerd into its word 
				this.logEvent(2, "Matched " token " to " this.map.qwerds.item(token).word)
				final_characters_count := StrLen(this.map.qwerds.item(token).word) + 1
				; expand this qwerd by first deleting the qwerd itself and its end character if not suppressed
				deleteChars := StrLen(token) + (not must_send_endkey)
				this.logEvent(4, "Sending " deleteChars " backspaces")
				Send, {Backspace %deleteChars%}
				this.logEvent(4, "Sending '" this.map.qwerds.item(token).word "'")
				Send, % this.map.qwerds.item(token).word
				
				; Expand the qwerd in the buffer as well 
				this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - StrLen(token))) this.map.qwerds.item(token).word end_char
				this.logEvent(4, "Buffer after expansion is '" this.input_text_buffer "'")
			} else {
				this.logEvent(2, "Control key down on match, so don't expand " token)
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(token) + 1
			}
			
			; We will always send suppressed keys later, so only send unsuppressed keys now 
			if (not must_send_endkey) {
				this.logEvent(2, "Sending end key, because it's not Enter or Tab")
				if (StrLen(key) = 1) {
					Switch key
					{
						Case "!":
							Send, {!}
						Case "^":
							Send, {@}
						Case "#":
							Send, {#}
						Case "+":
							Send, {+}
						Default:
							Send, % key
					}
				} else {
					Send, {%key%}
				}
			}
		} else {
			; This buffered input was not a special character, nor a qwerd
			this.logEvent(4, "No match on '" token "' and input text was '" input_text "'")
			if (input_text) {
				final_characters_count := StrLen(token) + 1
				if (this.map.hints.item(token).hint) {
					coaching := new CoachingEvent()
					coaching.word := token
					coaching.qwerd := this.map.hints.item(token).qwerd
					coaching.form := this.map.hints.item(token).form
					coaching.saves := -1 * this.map.hints.item(token).saves
					coaching.power := this.map.hints.item(token).power
					coaching.miss := true
					coaching.endKey := key
					this.coachQueue.enqueue(coaching)
					this.logEvent(3, "Enqueued failure coaching " coaching.word)
		
					this.flashTip(coaching)
					
					;;; Hintable
					this.logEvent(2, "Matched a hint " this.map.hints.item(token).hint)
				} else {
					; This is an unknown word and qwerd. Send it to coaching, but only if it's not too strange
					if (not RegExMatch(token, "[0-9!@#$%^&*]")) {
						coaching := new CoachingEvent()
						coaching.word := token
						coaching.other := 
						coaching.endKey := key
						this.coachQueue.enqueue(coaching)
						this.logEvent(3, "Enqueued unknown coaching " coaching.word)
					}
					;;; Ignorable 
					this.logEvent(3, "Unknown qwerd " token)
				}
			} else {
				this.logEvent(4, "No input_text, so not coachable - text from buffer only")
				final_characters_count := 0
			}
		}
		
		; Now append end char
		if (StrLen(key) = 1) { 
			this.input_text_buffer := this.input_text_buffer . key
			this.logEvent(4, "Buffer after appending end char '" this.input_text_buffer "'")
		} else if (key = "Backspace") {
			this.logEvent(4, "No end action on Backspace")
		} else {
			this.input_text_buffer := ""
			this.logEvent(4, "Buffer cleared for soft end character")
		}
		
		; Since we're suppressing these keys to make sure expansion happens before leaving a field, we must always send them
		if (must_send_endkey) {
			; Must send modifiers if we want them to appear, but must strip the < character from them 
			; clean_mods := StrReplace(mods, "<", "") 
			clean_mods := RegExReplace(mods, "[<>](.)(?:>\1)?", "$1")

			this.logEvent(2, "Forcing send of endkey '" key "' with mods " clean_mods)
			Send, %clean_mods%{%key%}
		}

		if (key == "'") {
			this.last_end_key := key
		} else if (key == "-") {
			if (token = "") {
				this.last_end_key := key
			} else {
				this.last_end_key := ""
			}
		} else {
			this.last_end_key := ""
		}

		if (input_text) {
			this.logEvent(3, "Enqueuing speed event " StrLen(token) + 1 " to " final_characters_count " in " ticks)
			event := new SpeedingEvent(A_Now, ticks, StrLen(token) + 1, final_characters_count, key)
			this.speedQueue.enqueue(event)
		} else {
			this.logEvent(3, "No input_text, so new speed event - text from buffer only")
		}
	}
	
	ResetInput()
	{
		this.logEvent(2, "Input reset by function ")
		this.ih.Stop()
	}
	
	flashTip(coachEvent) {
		if (coachEvent.power < this.tip_power_threshold) {
			return
		}
		Tooltip % coachEvent.word "=" coachEvent.qwerd, A_CaretX, A_CaretY + 30
		SetTimer, ClearToolTip, -1500
		return 

		ClearToolTip:
		  ToolTip
		return 
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
