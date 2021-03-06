engine := {}

class MappingEngine_InputHook
{
	Static MovementKeys := "{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}"
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	Static EndKeys_soft := "{LControl}{RControl}{backspace}{enter}{numpadenter}{tab}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}{LButton}"
	Static EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
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
	logVerbosity := 1
	tip_power_threshold := 2
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")
	
	nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

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
			this.ih.KeyOpt("{Enter}{Tab}{NumPadEnter}", "+S")
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

        this.maskToken := RegexMatch(input_text, "[0-9!@#$%\^&*<>?]")
		; First glue this input to the buffer 
        if (not this.maskToken) {
            this.logEvent(2, "Expanding '" input_text "' ended with '" key "' after " ticks " millis")
        } else {
            this.logEvent(2, "Expanding '****' ended with '" key "' after " ticks " millis")
        }
	    this.input_text_buffer := this.input_text_buffer . input_text
		if (StrLen(key) = 1) {
			this.input_text_buffer .= key
		}
        if (not this.maskToken) {
            this.logEvent(4, "Input_text after buffering '" this.input_text_buffer "'")
        } else {
            maskedBuffer := StrReplace(this.input_text_buffer, input_text, "****")
            this.logEvent(4, "Input_text after buffering '" this.maskedBuffer "'")
        }
		
		in_play_chars := this.getInPlayChars(this.input_text_buffer)
		inbound := this.parseInbound(in_play_chars)
        
        if (not this.maskToken) {
            this.logEvent(4, "We have an inbound " inbound.token)
        } else {
            this.logEvent(4, "We have a possible sensitive inbound ****")
        }
		
		;;; Now handle the token itself 
		if (key = "Backspace") {
			this.logEvent(4, "Handling backspace")
			final_characters_count := -1
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1))
		} else if (key == "LControl" or key == "RControl") {
			; The control key kills an input without expansion
			final_characters_count := StrLen(inbound.token) + 1
            if (not this.maskToken) {
                this.logEvent(3, "Cancelled via control key " inbound.token)
            } else {
                this.logEvent(3, "Cancelled via control key ****")
            }
		} else if (inbound.isContraction) {
			this.logEvent(4, "Handling apostrophe")
			; If the last input ended with ' and this input is a common contraction
			Switch inbound.token
			{
				Case "r":
					this.logEvent(4, "Handling 'r")
					Send, {Backspace}e
					Send, % key
					this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1)) "e" inbound.final_end_char
					final_characters_count := 3
				Case "v":
					this.logEvent(4, "Handling 'v")
					Send, {Backspace}e
					Send, % key
					this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1)) "e" inbound.final_end_char
					final_characters_count := 3
				Case "l":
					this.logEvent(4, "Handling 'l")
					Send, {Backspace}l
					Send, % key
					this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1)) "l" inbound.final_end_char
					final_characters_count := 3
				Default:
					this.logEvent(4, "Handling all others")
					final_characters_count := StrLen(inbound.token) + 1
			}
            if (not this.maskToken) {
                this.logEvent(3, "Completed contraction " inbound.token)
            } else {
                this.logEvent(3, "Completed contraction ****")
            }
		} else if (inbound.isCode) {
			this.logEvent(4, "Token is code and should not expand")
			final_characters_count := StrLen(inbound.token) + 1
		} else if (inbound.isAffix) {
			this.logEvent(4, "Handling join character")
			; If the last input began with -
			final_characters_count := StrLen(inbound.token) + 1
		} else if (this.map.qwerds.item(inbound.token).word) {
			if (not InStr(mods, "^")) {
				; Success 
				; Coach the found qwerd
				this.pushCoaching(this.map.qwerds.item(inbound.token), true, false, false, key)
				this.pushPenStroke(this.map.qwerds.item(inbound.token), "blue")
				
				; We will always send suppressed keys later, so only send unsuppressed keys now 
				if (not (InStr("NumpadEnterTab", key) > 0)) {
					this.logEvent(2, "Sending end key, because it's not going to be sent later like Enter or Tab")
					sendable_end_key := key
				} else {
					sendable_end_key := ""
				}
				
				final_characters_count := this.pushInput(inbound.token, this.map.qwerds.item(inbound.token).word, sendable_end_key)
				
			} else {
                if (not this.maskToken) {
                    this.logEvent(2, "Control key down on match, so don't expand " inbound.token)
                } else {
                    this.logEvent(2, "Control key down on match, so don't expand ****")
                }
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(inbound.token) + 1
			}
		} else {
			; This buffered input was not a special character, nor a qwerd
            if (not this.maskToken) {
                this.logEvent(4, "No match on '" inbound.token "' and input text was '" input_text "'")
            } else {
                this.logEvent(4, "No match on '****' and input text was '****'")
            }
			if (input_text) {
				final_characters_count := StrLen(inbound.token) + 1
				if (this.map.hints.item(inbound.token).hint) {
					this.pushCoaching(this.map.hints.item(inbound.token), false, true, false, key)
					this.pushPenStroke(this.map.hints.item(inbound.token), "red")
		
					;;; Hintable
					this.logEvent(2, "Matched a hint " this.map.hints.item(inbound.token).hint)
				} else {
					; This is an unknown word and qwerd. Send it to coaching, but only if it's not too strange
					if (not RegExMatch(inbound.token, "[0-9!@#$%^&*]")) {
						this.nullQwerd.word := inbound.token
						this.pushCoaching(this.nullQwerd, false, false, true, key)
						this.pushPenStroke(this.nullQwerd, "purple")
					}
					;;; Ignorable 
                    if (not this.maskToken) {
                        this.logEvent(3, "Unknown qwerd " inbound.token)
                    } else {
                        this.logEvent(3, "Unknown qwerd ****")
                    }
				}
			} else {
				this.logEvent(4, "No input_text, so not coachable - text from buffer only")
				final_characters_count := 0
			}
		}
		
		; Now append end char
		if (StrLen(key) = 1) { 
			;this.input_text_buffer := this.input_text_buffer . key
			this.logEvent(4, "Buffer after appending end char '" this.input_text_buffer "'")
		} else if (key = "Backspace") {
			this.logEvent(4, "No end action on Backspace")
		} else {
			this.input_text_buffer := ""
			this.logEvent(4, "Buffer cleared for soft end character")
		}
		
		; Since we're suppressing these keys to make sure expansion happens before leaving a field, we must always send them
		if (InStr("NumpadEnterTab", key) > 0) {
			; Must send modifiers if we want them to appear, but must strip the < character from them 
			; clean_mods := StrReplace(mods, "<", "") 
			clean_mods := RegExReplace(mods, "[<>](.)(?:>\1)?", "$1")

			this.logEvent(2, "Forcing send of endkey '" key "' with mods " clean_mods)
			Send, %clean_mods%{%key%}
		}

		if (key == "'") {
			this.last_end_key := key
		} else if (key == "-") {
			if (inbound.token = "") {
				this.last_end_key := key
			} else {
				this.last_end_key := ""
			}
		} else {
			this.last_end_key := ""
		}

		if (input_text) {
            this.logEvent(3, "Enqueuing speed event " StrLen(inbound.token) + 1 " to " final_characters_count " in " ticks)
			event := new SpeedingEvent(A_Now, ticks, StrLen(inbound.token) + 1, final_characters_count, key)
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
	
	getInPlayChars(buffer) {
		if (StrLen(buffer) > (this.map.longestQwerd + 1)) {
			in_play_chars := SubStr(buffer, (StrLen(buffer) - (this.map.longestQwerd + 1)))
		} else {
			in_play_chars := buffer
		}
        if (not this.maskToken) {
            this.logEvent(4, "In play chars are '" in_play_chars "'")
        } else {
            this.logEvent(4, "In play chars are '****'")
        }
        
		return in_play_chars
		
	}
	
	parseInbound(in_play_chars) {
		; Strategy: Reverse the chars, pick the last end char, the token, the first end char, and the preceding
		;	Make decisions based upon those 4 pieces of data
		inbound := {}
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
				if (A_Index = 1) {
					inbound.final_end_char := A_LoopField
				} else {
					inbound.initial_end_char := A_LoopField
					finding_preceding_char := true 
				}
			}
		}
		DllCall("msvcrt.dll\_wcsrev", "Ptr", &token, "CDecl")
		inbound.token := token
		
		; Decisions
		inbound.hasToken := (StrLen(inbound.token) > 0)
		inbound.isCode := (((inbound.preceding_char == " ") or (inbound.preceding_char == "")) and ((inbound.initial_end_char) and (InStr("-:/", inbound.initial_end_char))))
		inbound.isContraction := ((inbound.initial_end_char == "'") and (inbound.preceding_char) and (InStr(MappingEngine_InputHook.ContractedEndings,inbound.token)))
		inbound.isAffix := false
		
        if (not this.maskToken) {
            this.logEvent(4, "Inbound pre,end1,token,end2 '" inbound.preceding_char "','" inbound.initial_end_char "','" inbound.token "','" inbound.final_end_char "'")
            this.logEvent(4, "hasToken = " inbound.hasToken ", and isCode = " inbound.isCode)
        } else {
            this.logEvent(4, "Inbound pre,end1,token,end2 '" inbound.preceding_char "','" inbound.initial_end_char "','****','" inbound.final_end_char "'")
            this.logEvent(4, "hasToken = " inbound.hasToken ", and isCode = " inbound.isCode)
        }
		return inbound
	}
	
	pushInput(qwerd, word, end_key) {
		
		;;; Expand the qwerd into its word 
		this.logEvent(2, "Pushing " qwerd " to " word " ending with " end_key)
		final_characters_count := StrLen(word) + 1
		; expand this qwerd by first deleting the qwerd itself and its end character if not suppressed
		deleteChars := StrLen(qwerd) + (InStr("NumpadEnterTab", end_key) = 0)
		this.logEvent(4, "Sending " deleteChars " backspaces")
		Send, {Backspace %deleteChars%}
		this.logEvent(4, "Sending '" word "'")
		Send, % word
		
		; Expand the qwerd into the buffer as well 
		this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - (StrLen(qwerd) + (InStr("NumpadEnterTab", end_key) = 0)))) word

		if (StrLen(end_key) = 1) {
			; handle these special characters explicitly, or they'll be interpreted as modifiers
			Switch end_key
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
					Send, % end_key
			}
			this.input_text_buffer .= end_key
		} else {
			Send, {%end_key%}
			this.input_text_buffer := ""
		}
		
		this.logEvent(4, "Buffer after expansion is '" this.input_text_buffer "'")
		
		return final_characters_count
	}
	
	pushCoaching(qwerd, match, miss, other, key) {
		coaching := new CoachingEvent()
		coaching.word := qwerd.word
		coaching.qwerd := qwerd.qwerd
		coaching.form := qwerd.form
		coaching.saves := qwerd.saves
		coaching.power := qwerd.power
		coaching.match := match
		coaching.miss := miss
		coaching.other := other
		coaching.endKey := key
		this.coachQueue.enqueue(coaching)
		this.logEvent(3, "Enqueued coaching " coaching.word)
		
		if (miss) { 
			this.flashTip(coaching)
		}
	}
	
	pushPenStroke(qwerd, ink) {
		penAction := new PenEvent(qwerd.form, qwerd.qwerd, qwerd.word, ink)
		this.penQueue.enqueue(penAction)
		this.logEvent(4, "Enqueued pen action '" penAction.form "'")
	}
	
	flashTip(coachEvent) {
		if (coachEvent.power < this.tip_power_threshold) {
			return
		}
		Tooltip % coachEvent.word " = " coachEvent.qwerd, A_CaretX, A_CaretY + 30
		SetTimer, ClearToolTipEngine, -1500
		return 

		ClearToolTipEngine:
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
