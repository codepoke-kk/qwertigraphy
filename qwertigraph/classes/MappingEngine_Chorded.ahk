engine := {}

class MappingEngine_Chorded
{
	Static MovementKeys := "{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}"
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	Static EndKeys_soft := "{LControl}{RControl}{backspace}{enter}{numpadenter}{tab}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}{LButton}"
	Static EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
	Static EndKeys := MappingEngine_Chorded.EndKeys_soft MappingEngine_Chorded.EndKeys_hard
	
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
	tip_power_threshold := 1
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")
	
	keyboard := {}
	keyboard.MovementKeys := "{home}{end}{pgup}{pgdn}{left}{up}{right}{down}{lbutton}{backspace}"
	keyboard.EditKeys := "{enter}{numpadenter}{tab}{delete}{insert}"
	keyboard.SpecialKeys := "{}!#^*"
	keyboard.EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
    keyboard.ShiftedNumerals := {"1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^", "7": "&", "8": "*", "9": "(", "0": ")"}
	keyboard.DownKeys := ""
	keyboard.Shfed := ""
	keyboard.Ctled := ""
	keyboard.Alted := ""
	keyboard.Wined := ""
	keyboard.Token := ""
	keyboard.TokenStartTicks := A_TickCount
	keyboard.CapsLock := false
	keyboard.ChordLength := 0
	keyboard.MaxChordLength := 0
	keyboard.ChordReleaseStartTicks := 0
	keyboard.AutoSpaceSent := true
	keyboard.ChordReleaseWindow := 70
	
	nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

	__New(map)
	{
		this.map := map
	}
		
	Start() 
	{
		this.keyboard.Token := ""
		this.input_text_buffer := ""
		this.logEvent(1, "Starting" )
		this.ih := InputHook("EL0I1")
		this.ih.KeyOpt("{All}", "NS")  ; End and Suppress
		;this.ih.OnKeyDown := Func("this.ReceiveKeyDown")
		this.ih.OnKeyDown := ObjBindMethod(this, "ReceiveKeyDown")
		;this.ih.OnKeyUp := Func("this.ReceiveKeyUp")
		this.ih.OnKeyUp := ObjBindMethod(this, "ReceiveKeyUp")
		this.ih.Start()	
	}	 
		
	Stop() 
	{
		this.logEvent(1, "Stopping" )
		this.ih.KeyOpt("{All}", "-N-S")  ; Undo end and Suppress
		this.ih.Stop()
		this.keyboard.Token := ""
		this.logEvent(1, "Stopped" )
	}
	
	ReceiveKeyDown(InputHook, VK, SC) {
		local key
		; ToolTip, % "VK: " VK ", SC: " SC
		key := GetKeyName(Format("vk{:x}", VK))
		Switch key
		{
			case "p": 
				; We need a way to stop all input
				if (this.keyboard.Alted and this.keyboard.Wined) {
					sendkey := key
					this.CancelToken(sendkey)
					this.Stop()
				} else {
					; ToolTip, % "Our P has " this.keyboard.Ctled "and" this.keyboard.Wined "and" this.keyboard.Alted
					this.AddToToken(key)
					sendkey := key
				}
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				this.AddToToken(key)
				sendkey := key
			case "n", "o", "r", "q", "s", "t", "u", "v", "w", "x", "y", "z": 
				this.AddToToken(key)
				sendkey := key
			case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				sendkey := key
				if (this.keyboard.Shfed) {
                    shiftedKey := this.keyboard.ShiftedNumerals[key]
					this.SendToken(shiftedKey)
				} else {
					this.AddToToken(key)
				}
			case ".", ",", "/", "'", ";", "[", "]", "\", "-", "=", "``": 
				sendkey := key 
				this.SendToken(sendkey)
			case "Space":
				sendKey := "{" key "}"
				this.SendToken(sendKey)
			case "Enter", "Tab", "Insert", "NumPadEnter":
				sendKey := "{" key "}"
				this.SendToken(sendkey)
			case "Home", "End", "PgUp", "PgDn", "Left", "Up", "Right", "Down", "NumpadHome", "NumpadEnd", "NumpadPgUp", "NumpadPgDn", "NumpadLeft", "NumpadUp", "NumpadRight", "NumpadDown", "NumpadDel", "Delete":
				sendKey := "{" key "}"
				this.CancelToken(sendkey)
			case "Backspace":
				sendKey := "{" key "}"
				this.RemoveKeyFromToken()
			case "CapsLock":
				if (this.keyboard.CapsLock) {
					this.keyboard.Shfed := ""
					this.keyboard.CapsLock := false
				} else {
					this.keyboard.Shfed := "+"
					this.keyboard.CapsLock := true
				}
				sendKey := ""
			case "LShift":
				Send, {Lshift down}
				this.keyboard.Shfed := "+"
				sendKey := ""
			case "RShift":
				Send, {RShift down}
				this.keyboard.Shfed := "+"
				sendKey := ""
			case "LControl":
				Send, {LControl down}
				this.keyboard.Ctled := "^"
				sendKey := ""
				this.CancelToken(key)
			case "RControl":
				Send, {RControl down}
				this.keyboard.Ctled := "^"
				sendKey := ""
				this.CancelToken(key)
			case "LAlt":
				Send, {LAlt down}
				this.keyboard.Alted := "!"
				sendKey := ""
				this.CancelToken(key)
			case "RAlt":
				Send, {RAlt down}
				this.keyboard.Alted := "!"
				sendKey := ""
				this.CancelToken(key)
			case "LWin":
				Send, {LWin down}
				this.keyboard.Wined := "#"
				sendKey := ""
				this.CancelToken(key)
			case "RWin":
				Send, {RWin down}
				this.keyboard.Wined := "#"
				sendKey := ""
				this.CancelToken(key)
			default:
				sendKey := "{" key "}"
				ToolTip, % "Unknown key: " key
				SetTimer, ClearToolTipEngine, -1500
				this.SendToken(key)
		} 
		; Send, % sendKey
		Send, % this.keyboard.Shfed this.keyboard.Ctled this.keyboard.Alted this.keyboard.Wined sendKey
	}

	ReceiveKeyUp(InputHook, VK, SC) {
		local key
		key := GetKeyName(Format("vk{:x}", VK))
		Switch key
		{
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				this.LeaveChord(key)
			case "n", "o", "p", "r", "q", "s", "t", "u", "v", "w", "x", "y", "z": 
				this.LeaveChord(key)
			case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
				this.LeaveChord(key)
			case "LShift":
				Send, {LShift up}
				this.keyboard.Shfed := ""
			case "RShift":
				Send, {RShift up}
				this.keyboard.Shfed := ""
			case "LControl":
				Send, {LControl up}
				this.keyboard.Ctled := ""
				this.CancelToken(key)
			case "RControl":
				Send, {RControl up}
				this.keyboard.Ctled := ""
				this.CancelToken(key)
			case "LAlt":
				Send, {LAlt up}
				this.keyboard.Alted := ""
				this.CancelToken(key)
			case "RAlt":
				Send, {RAlt up}
				this.keyboard.Alted := ""
				this.CancelToken(key)
			case "LWin":
				Send, {LWin up}
				this.keyboard.Wined := ""
				this.CancelToken(key)
			case "RWin":
				Send, {RWin up}
				this.keyboard.Wined := ""
				this.CancelToken(key)
		} 
	}

	AddToToken(key) {
		; Accumulate this letter
		if (this.keyboard.Shfed) {
			StringUpper key, key
		} 
		this.keyboard.Token .= key
		this.JoinChord(key)
	}

	RemoveKeyFromToken() {
		; This is a backspace
		if (not StrLen(this.keyboard.Token)) {
			; If we are deleting things written before this token, we have to take from the buffer
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1))
		}
		this.keyboard.Token := SubStr(this.keyboard.Token, 1, (StrLen(this.keyboard.Token) - 1))
		; We have to reset the deletion of the auto space, or it will double delete
		this.keyboard.AutoSpaceSent := false
	}

	CancelToken(key) {
		; Send the empty key through to clear the input buffer
		this.keyboard.Token := ""
		this.input_text_buffer := ""
		this.keyboard.AutoSpaceSent := false
		this.ExpandInput(this.keyboard.Token, key, (this.keyboard.Shfed this.keyboard.Ctled this.keyboard.Alted this.keyboard.Wined), (A_TickCount - this.keyboard.TokenStartTicks))
	}

	SendToken(key) {
		; Send through a valid qwerd because an end character was typed 
		if (this.keyboard.AutoSpaceSent) {
			; We sent a space after sending a chord. 
			if (not this.keyboard.Token) {
				; if this is a bare end key, then we need to delete that autospace
				Send, {Backspace}
			}
		}
        ; Bug in 1.1.32.00 causes shift key to stick
        Send, {LShift up}{RShift up}
		this.ExpandInput(this.keyboard.Token, key, (this.keyboard.Shfed this.keyboard.Ctled this.keyboard.Alted this.keyboard.Wined), (A_TickCount - this.keyboard.TokenStartTicks))
		this.keyboard.Token := ""
		this.keyboard.TokenStartTicks := A_TickCount
		this.keyboard.AutoSpaceSent := false
		; SetTimer, ClearToolTipEngine, -1500
	}	

	JoinChord(key) {
		; This is a chordable keydown event
		this.logEvent(4, "Chord: join candidate " key " from count " this.keyboard.ChordLength " with max length " this.keyboard.MaxChordLength)
		if (this.keyboard.ChordLength = this.keyboard.MaxChordLength) {
			; If any key comes up, the chord entry portion is over, so chord length should always be max when valid
			this.keyboard.ChordLength += 1
		} else {
			; Some key came up, so chord length must be smaller than max. Kill the chord
			this.keyboard.ChordLength := 0
			this.keyboard.ChordReleaseStartTicks := 0
		}
		; In any case the max length should now be the chord length
		this.keyboard.MaxChordLength := this.keyboard.ChordLength
		this.logEvent(4, "Chord: joining " key " for count " this.keyboard.ChordLength)
	}
	LeaveChord(key) {
		; This is a chordable keyup event 
		if (this.keyboard.ChordLength > 1) {
			; If we have input of 2 or more characters, then let's see if it's valid
			if (this.keyboard.ChordLength = this.keyboard.MaxChordLength) {
				; This is the first key to come back up, so start the timing of whether they all come up together 
				this.keyboard.ChordReleaseStartTicks := A_TickCount
				this.logEvent(4, "Chord: first leaving " key " at " this.keyboard.ChordReleaseStartTicks)
			} else {
				; This is a subsequent key, but not the last key. Just log it 
				this.logEvent(4, "Chord: next leaving " key)
			}
			; Now decrement the remaining chord length
			this.keyboard.ChordLength -= 1
		} else if (this.keyboard.ChordLength = 1) {
			; This is the release of the last key in the chord
			chordWindow := A_TickCount - this.keyboard.ChordReleaseStartTicks
			if ((StrLen(this.keyboard.Token) >= this.map.minimumChordLength) 
				and (chordWindow > 0) 
				and (chordWindow < this.keyboard.ChordReleaseWindow) 
				and (StrLen(this.keyboard.Token) = this.keyboard.MaxChordLength)) {
				; The time is quick enough to call a chord 
				this.logEvent(2, "ChordWindow: completed " this.keyboard.Token " in " chordWindow "ms")
				this.keyboard.ChordLength := 0
				this.keyboard.MaxChordLength := 0
				this.SendChord()
			} else {
				; Too slow. Let this be serial input
				this.logEvent(2, "ChordWindow: too short or timed out " this.keyboard.Token " in " chordWindow "ms against " this.keyboard.ChordReleaseWindow)
				this.keyboard.ChordLength := 0
				this.keyboard.MaxChordLength := 0
			}
			; Whether chorded or serial, reset everything
		} else {
			this.logEvent(4, "Chord: already zero, so this chord was interrupted " key)
			this.keyboard.MaxChordLength := 0
		}
	}
	SendChord() {
		; Send through a possible chord
		chord := this.map.AlphaOrder(this.keyboard.Token)
		if (this.keyboard.Shfed) {
			StringUpper, chord, chord
		}
		if (this.map.chords.item(chord).word) {
			; Sleep long enough to see whether another key is pressed
			; Sleep, this.keyboard.ChordReleaseWindow
			if (not this.keyboard.ChordLength) {
				this.logEvent(2, "Chord: allowed because no other key was struck")
				; The sorted input is a valid chord, so push it as input
				this.logEvent(4, "Chord " chord " found for " this.map.chords.item(chord).word)
				this.ExpandInput(chord, "{Chord}", (this.keyboard.Shfed this.keyboard.Ctled this.keyboard.Alted this.keyboard.Wined), (A_TickCount - this.keyboard.TokenStartTicks))
				Send, {Space}
				; Mark that we sent this as a chord, so we know we need to send a backspace before the next end char
				this.keyboard.AutoSpaceSent := true
				; Reset the input token 
				this.keyboard.Token := ""
				this.keyboard.TokenStartTicks := A_TickCount
			} else {
				this.logEvent(2, "Chord: aborted because another key was struck")
			}
		} else {
			this.logEvent(4, "Chord " chord " not found. Allow input to complete in serial fashion")
		}
	}

	ExpandInput(input_text, key, mods, ticks) {
		this.logEvent(4, "Expanding |" input_text "|" key "|" mods "|" ticks "|" )
		if (key = "{Chord}") {
			;ToolTip, % "Chording " input_text, A_CaretX, A_CaretY + 30
			;SetTimer, ClearToolTipEngine, -1500
			this.logEvent(4, "Chording " input_text )
		} else {
			this.logEvent(4, "Serialing " input_text)
			this.keyboard.MaxChordLength := 0
		}
        
	    this.input_text_buffer .= input_text
		in_play_chars := this.getInPlayChars(this.input_text_buffer)
		inbound := this.parseInbound(in_play_chars, key)

		this.logEvent(4, "Input_text after buffering '" this.input_text_buffer "'")
		
        if (inbound.sensitive) {
            this.logEvent(4, "We have a possible sensitive inbound ****")
        }
		
		;;; Now handle the token itself 
		;;; Events with no input_text, only an end character 
		if (key = "{Backspace}") {
			this.logEvent(4, "Handling backspace")
			final_characters_count := -1
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - 1))
		} else if (key == "{LControl}" or key == "{RControl}") {
			; The control key kills an input without expansion
			final_characters_count := StrLen(inbound.token) + 1
			this.logEvent(4, "Cancelled via control key " inbound.token)
		} else if (inbound.isContraction) {
			this.logEvent(4, "Handling apostrophe as contraction")
			; If the last input ended with ' and this input is a common contraction
			Switch inbound.token
			{
				Case "r":
					this.logEvent(4, "Handling 'r")
					Send, e
					this.input_text_buffer .= "e"
					final_characters_count := 3
				Case "v":
					this.logEvent(4, "Handling 'v")
					Send, e
					this.input_text_buffer .= "e"
					final_characters_count := 3
				Case "l":
					this.logEvent(4, "Handling 'l")
					Send, l
					this.input_text_buffer .= "l"
					final_characters_count := 3
				Default:
					this.logEvent(4, "Handling all others")
					final_characters_count := StrLen(inbound.token) + 1
			}
			this.logEvent(4, "Completed contraction " inbound.token)
		} else if (inbound.isCode) {
			this.logEvent(4, "Token is code and should not expand")
			final_characters_count := StrLen(inbound.token) + 1
		} else if (inbound.isAffix) {
			this.logEvent(4, "Handling join character")
			; If the last input began with -
			final_characters_count := StrLen(inbound.token) + 1
		;;; Now handle input with possible qwerd
		} else if (key = "{Chord}") {
			; This is a chorded expansion
			; Do not try to match if the control key is down 
			if (not InStr(mods, "^")) {
				; Success 
				; Coach the found qwerd
				this.pushCoaching(this.map.chords.item(inbound.token), true, false, false, key, 1)
				this.pushPenStroke(this.map.chords.item(inbound.token), "blue")
				; "Push Input" is where the magic happens on screen
				final_characters_count := this.pushInput(inbound.token, this.map.chords.item(inbound.token).word, key)
			} else {
				this.logEvent(2, "Control key down on match, so don't expand " inbound.token)
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(inbound.token) + 1
			}
		} else if (this.map.qwerds.item(inbound.token).word) {
			; This is a serial expansion
			; Do not try to match if the control key is down 
			if (not InStr(mods, "^")) {
				; Success 
				; Coach the found qwerd
				this.pushCoaching(this.map.qwerds.item(inbound.token), true, false, false, key, 0)
				this.pushPenStroke(this.map.qwerds.item(inbound.token), "blue")
				; "Push Input" is where the magic happens on screen
				final_characters_count := this.pushInput(inbound.token, this.map.qwerds.item(inbound.token).word, key)
			} else {
				this.logEvent(2, "Control key down on match, so don't expand " inbound.token)
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(inbound.token) + 1
			}
		} else {
			; This buffered input was not a special character, nor a qwerd
			this.logEvent(4, "No match on '" inbound.token "' and input text was '" input_text "'")
			if (input_text) {
				final_characters_count := StrLen(inbound.token) + 1
				if (this.map.hints.item(inbound.token).hint) {
					this.pushCoaching(this.map.hints.item(inbound.token), false, true, false, key, 0)
					this.pushPenStroke(this.map.hints.item(inbound.token), "red")
		
					;;; Hintable
					this.logEvent(2, "Matched a hint " this.map.hints.item(inbound.token).hint)
				} else {
					; This is an unknown word and qwerd. Send it to coaching, but only if it's not too strange
					if (not inbound.isSensitive) {
						this.nullQwerd.word := inbound.token
						this.pushCoaching(this.nullQwerd, false, false, true, key, (StrLen(inbound.token)))
						this.pushPenStroke(this.nullQwerd, "purple")
					}
					;;; Ignorable 
					this.logEvent(4, "Unknown qwerd " inbound.token)
				}
			} else {
				this.logEvent(4, "No input_text, so not coachable - text from buffer only")
				final_characters_count := 0
			}
		}
		
		; Now append end char to input buffer
		if (StrLen(key) = 1) { 
			this.input_text_buffer .= key
		} else if (key = "{Space}") {
			this.input_text_buffer .= " "
		} else if (key = "{Backspace}") {
			;this.logEvent(4, "No end action on Backspace")
		} else {
			this.input_text_buffer := ""
		}
		this.logEvent(4, "Final input buffer '" this.input_text_buffer "'")

		; Track last end key for parsing the next word 
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
		this.logEvent(4, "Last end key '" this.last_end_key "'")

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
		;this.ih.Stop()
		;this.Start()
		this.CancelToken("{LButton}")
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
		inbound.isCode := (((inbound.preceding_char == " ") or (inbound.preceding_char == "")) and ((inbound.initial_end_char) and (InStr("-:/", inbound.initial_end_char))))
		; Might this be a password?
        inbound.isSensitive := RegexMatch(inbound.token, "[0-9!@#$%\^&*<>?]")
		; Like "there's"
		inbound.isContraction := ((inbound.initial_end_char == "'") and (inbound.preceding_char) and (InStr(MappingEngine_Chorded.ContractedEndings,inbound.token)))
		inbound.isAffix := false
		
		this.logEvent(4, "Inbound pre|end1|token|end2 |" inbound.preceding_char "|" inbound.initial_end_char "|" inbound.token "|" inbound.final_end_char "|")
		this.logEvent(4, "hasToken = " inbound.hasToken ", and isCode = " inbound.isCode ", and isSensitive = " inbound.isSensitive ", and isContraction = " inbound.isContraction)
		return inbound
	}
	
	pushInput(qwerd, word, end_key) {
		
		;;; Expand the qwerd into its word 
		this.logEvent(2, "Pushing " qwerd " to " word " ending with " end_key)
		final_characters_count := StrLen(word) + 1
		; expand this qwerd by first deleting the qwerd itself and its end character if not suppressed
		deleteChars := StrLen(qwerd)
		if (not this.keyboard.AutoSpaceSent) {
			;deleteChars++
		}
		this.logEvent(4, "Sending " deleteChars " backspaces")
		Send, {Backspace %deleteChars%}
		this.logEvent(4, "Sending '" word "'")
        ; Msgbox, % "Hold"
		Send, % word
		
		;;; Expand the qwerd into the buffer as well 
		this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - (StrLen(qwerd)))) word
		
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
	
	pushPenStroke(qwerd, ink) {
		penAction := new PenEvent(qwerd.form, qwerd.qwerd, qwerd.word, ink)
		this.penQueue.enqueue(penAction)
		this.logEvent(4, "Enqueued pen action '" penAction.form "'")
	}
	
	flashTip(coachEvent) {
		if (coachEvent.power < this.tip_power_threshold) {
			return
		}
		if (coachEvent.chordable = "active") {
			Tooltip % coachEvent.word " = " coachEvent.qwerd " (" coachEvent.chord ")", A_CaretX, A_CaretY + 30
		} else {
			Tooltip % coachEvent.word " = " coachEvent.qwerd, A_CaretX, A_CaretY + 30
		}
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
