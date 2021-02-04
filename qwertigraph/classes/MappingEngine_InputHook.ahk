
class MappingEngine_InputHook
{
	Static MovementKeys := "{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}"
	Static ContractedEndings := "s,d,t,m,re,ve,ll"
	Static EndKeys := "{LControl}{RControl}{backspace}{enter}{tab}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}{space}.,?!;:'""-_{{}{}}[]/+=|{LButton}"

	map := ""
	ih := ""
	last_end_key := ""
	characters_typed_raw := ""
	characters_typed_final := ""
	time_taken := ""
	average_raw_wpm := ""
	average_final_wpm := ""
	discard_ratio := ""
	input_text_backspace_buffer := ""
	last_input_text_backspace_buffer := ""
	logQueue := new Queue("EngineQueue")
	logVerbosity := 2
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")

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

		this.logEvent(2, "Expanding " input_text " ended with " key " after " ticks " millis")
		buffered_input_text := this.input_text_backspace_buffer . input_text
		this.logEvent(4, "Input_text after buffering " buffered_input_text)
		
		; Suppressing Enter and Tab, to keep them from messing up field inputs. We'll have to send them every time
		must_send_endkey := (InStr("Enter Tab", key) > 0)

		if ((this.last_end_key == "'") and (InStr(MappingEngine_InputHook.ContractedEndings,buffered_input_text))) {
			; If the last input ended with ' and this input is a common contraction, do nothing 
			final_characters_count := StrLen(buffered_input_text) + 1
			this.logEvent(3, "Completed contraction " buffered_input_text)
		} else if (this.last_end_key == "-") {
			; If the last input ended with a hyphen per standards found below, do not expand since this is a Unix parameter flag
			final_characters_count := StrLen(buffered_input_text) + 1
			this.logEvent(3, "Completed hyphen " buffered_input_text)
		} else if (key == "LControl" or key == "RControl") {
			; The control key kills an input without expansion
			final_characters_count := StrLen(buffered_input_text) + 1
			this.logEvent(3, "Cancelled via control key " buffered_input_text)
		} else if (key = "backspace") {
			; Get fancy here to allow backspace to re-activate the last input
			if (not InStr(mods, "^")) {
				this.logEvent(4, "Did a backspace after " buffered_input_text " buffering " this.input_text_backspace_buffer)
				if (buffered_input_text = "") {
					this.logEvent(4, "Backspaced with an empty buffer. Retrieving last buffer " this.last_input_text_backspace_buffer)
					buffered_input_text := this.last_input_text_backspace_buffer
					this.input_text_backspace_buffer := this.last_input_text_backspace_buffer
					this.last_input_text_backspace_buffer := ""
				}
				this.input_text_backspace_buffer := SubStr(buffered_input_text, 1, (StrLen(buffered_input_text) - 1))
				final_characters_count := StrLen(buffered_input_text)
				this.logEvent(3, "Did a backspace after " buffered_input_text " buffering " this.input_text_backspace_buffer)
			} else {
				; Control-backspace resets all buffers
				this.logEvent(4, "Did a control-backspace after " buffered_input_text " buffering " this.input_text_backspace_buffer)
				buffered_input_text := ""
				this.input_text_backspace_buffer := ""
				this.last_input_text_backspace_buffer := ""
				final_characters_count := 0
			}
		} else if (this.map.qwerds.item(buffered_input_text).word) {
			if (not InStr(mods, "^")) {
				coaching := new CoachingEvent()
				coaching.word := this.map.qwerds.item(buffered_input_text).word
				coaching.qwerd := buffered_input_text
				coaching.form := this.map.qwerds.item(buffered_input_text).form
				coaching.saves := this.map.qwerds.item(buffered_input_text).saves
				coaching.power := this.map.qwerds.item(buffered_input_text).power
				coaching.match := true
				coaching.endKey := key
				this.coachQueue.enqueue(coaching)
				;;; Expandable
				this.logEvent(2, "Matched a qwerd " this.map.qwerds.item(buffered_input_text).word)
				final_characters_count := StrLen(this.map.qwerds.item(buffered_input_text).word) + 1
				; expand this qwerd by first deleting the qwerd itself and its end character if not suppressed
				deleteChars := StrLen(buffered_input_text) + (not must_send_endkey)
				Send, {Backspace %deleteChars%}
				this.logEvent(4, "Sending " this.map.qwerds.item(buffered_input_text).word)
				Send, % this.map.qwerds.item(buffered_input_text).word
			  this.input_text_backspace_buffer := ""
			} else {
				this.logEvent(2, "Control key down, so don't expand " buffered_input_text)
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(buffered_input_text) + 1
			}
			
			; We will always send suppressed keys later, so only send unsuppressed keys now 
			if (not must_send_endkey) {
				this.logEvent(2, "Sending end key, because it's not Enter or Tab")
				Send, {%key%}
			}
		} else {
			; This buffered input was not a special character, nor a qwerd
			; Keep the buffer for later backspace tracking
			this.logEvent(4, "Double buffering " this.input_text_backspace_buffer)
			this.last_input_text_backspace_buffer := input_text "+" 
			final_characters_count := StrLen(buffered_input_text) + 1
			this.logEvent(4, "No match for " buffered_input_text ", so deleting " this.input_text_backspace_buffer)
			this.input_text_backspace_buffer := ""
			if (this.map.hints.item(buffered_input_text).hint) {
				coaching := new CoachingEvent()
				coaching.word := buffered_input_text
				coaching.qwerd := this.map.hints.item(buffered_input_text).qwerd
				coaching.form := this.map.hints.item(buffered_input_text).form
				coaching.saves := this.map.hints.item(buffered_input_text).saves
				coaching.power := this.map.hints.item(buffered_input_text).power
				coaching.miss := true
				coaching.endKey := key
				this.coachQueue.enqueue(coaching)
				;;; Hintable
				this.logEvent(2, "Matched a hint " this.map.hints.item(buffered_input_text).hint)
				; FlashHint(this.map.hints.item(buffered_input_text).hint)
			} else {
				; This is an unknown word and qwerd. Send it to coaching, but only if it's not too strange
				if (not RegExMatch(buffered_input_text, "[0-9!@#$%^&*]")) {
					coaching := new CoachingEvent()
					coaching.word := buffered_input_text
					coaching.other := 
					coaching.endKey := key
					this.coachQueue.enqueue(coaching)
				}
				;;; Ignorable 
				this.logEvent(3, "Unknown qwerd")
			}
		}
		
		; Since we're suppressing these keys to make sure expansion happens before leaving a field, we must always send them
		if (must_send_endkey) {
			; Must send modifiers if we want them to appear, but must strip the < character from them 
			; clean_mods := StrReplace(mods, "<", "") 
			clean_mods := RegExReplace(mods, "[<>](.)(?:>\1)?", "$1")

			this.logEvent(2, "Forcing send of endkey " key " with mods " clean_mods)
			Send, %clean_mods%{%key%}
		}

		if (key == "'") {
			this.last_end_key := key
		} else if (key == "-") {
			if (buffered_input_text = "") {
				this.last_end_key := key
			} else {
				this.last_end_key := ""
			}
		} else {
			this.last_end_key := ""
		}

		event := new SpeedingEvent(A_Now, ticks, StrLen(buffered_input_text) + 1, final_characters_count, key)
		this.speedQueue.enqueue(event)
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
