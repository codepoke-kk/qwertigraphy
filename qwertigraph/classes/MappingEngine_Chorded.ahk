#InstallKeybdHook
engine := {}

#Include %A_AppData%\Qwertigraph\personal_functions.ahk
#Include scripts\default.ahk

class MappingEngine_Chorded
{
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	
	map := ""
	dashboard := ""
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
	tip_power_threshold := 1
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")
	dashboardQueue := new Queue("DashboardQueue")
	
	keyboard := {}
	keyboard.EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
	keyboard.Letters := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
	keyboard.Numerals := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	keyboard.ShiftedNumerals := ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
	keyboard.Token := ""
	keyboard.TokenStartTicks := A_TickCount
	keyboard.CapsLock := false
	keyboard.ChordLength := 0
	keyboard.MaxChordLength := 0
	keyboard.ChordPressStartTicks := 0
	keyboard.ChordReleaseStartTicks := 0
	keyboard.ScriptCalled := false
	keyboard.AutoSpaceSent := true
	keyboard.AutoPunctuationSent := false
	keyboard.ChordReleaseWindow := 150
    keyboard.ChordReleaseWindows := []
	keyboard.CoachAheadLines := 100
	keyboard.CoachAheadTipDuration := 5000
	keyboard.CoachAheadWait := 1000
	
	nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

	__New(map)
	{
		this.map := map
		this.keyboard.ChordReleaseWindow := this.map.qenv.properties.ChordWindow
		this.keyboard.CoachAheadLines := this.map.qenv.properties.CoachAheadLines
		this.keyboard.CoachAheadTipDuration := this.map.qenv.properties.CoachAheadTipDuration
		this.keyboard.CoachAheadWait := this.map.qenv.properties.CoachAheadWait
		this.logVerbosity := this.map.qenv.properties.LoggingLevelEngine
		this.dashboard := ""
		
        this.setKeyboardChordWindowIncrements()
	}
		
	Start() 
	{
		this.logEvent(3, "Property test: " this.map.qenv.properties.ChordWindow)
		
        this.ResyncModifierKeys()
		this.keyboard.Token := ""
		this.input_text_buffer := ""
		this.logEvent(1, "Starting" )
		this.ih := InputHook("EL0I1")
		this.ih.KeyOpt("{All}", "NS")  ; End and Suppress
		this.ih.KeyOpt("{CapsLock}", "V") 
		this.ih.KeyOpt("{LShift}", "V") 
		this.ih.KeyOpt("{RShift}", "V") 
		this.ih.KeyOpt("{LControl}", "V") 
		this.ih.KeyOpt("{RControl}", "V") 
		this.ih.KeyOpt("{LAlt}", "V") 
		this.ih.KeyOpt("{rAlt}", "V") 
		this.ih.KeyOpt("{LWin}", "V") 
		this.ih.KeyOpt("{RWin}", "V") 
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
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				this.AddToToken(key)
				sendkey := key
			case "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
				this.AddToToken(key)
				sendkey := key
			case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				sendkey := key
				if (GetKeyState("Shift", "P")) {
					if (key == "0") {
						key := "10"
					}
                    shiftedKey := this.keyboard.ShiftedNumerals[key]
					if (InStr("@&", shiftedKey)) {
						this.CancelToken(shiftedKey)
					} else {
						sendKey := ""
						this.SendToken("{" shiftedKey "}")
					}
				} else {
					this.AddToToken(key)
				}
			case ".", ",", "'",  "[", "]": 
				sendkey := ""
				if (not GetKeyState("Control", "P")) {
					this.SendToken(key)
				} else {
					this.CancelToken("{Ctrl-" key "}")
					Send, % key
				}
			case "/", ";", "[", "]", "\", "-", "=": 
				; sendkey := key
				; this.CancelToken(key)
                ; Revert behavior
				sendkey := ""
				this.SendToken(key)
			case "``": 
                ; Let the backtick serve as a token cancel key. 
                ; I could also let it pass through, then it would be backtick backspace to cancel, but let's try this 
				sendKey := ""
				this.CancelToken(sendkey)
			case "Space":
				sendkey := ""
				if (not GetKeyState("Control", "P")) {
					this.SendToken("{" key "}")
				} else {
					this.CancelToken("{Ctrl-space}")
					Send, % " "
				}
			case "Enter", "Tab", "Insert", "NumPadEnter":
				sendKey := ""
				if (not GetKeyState("Control", "P")) {
					this.SendToken("{" key "}")
				} else {
					this.CancelToken("{Ctrl-" key "}")
					Send, % "{" key "}"
				}
			case "Home", "End", "PgUp", "PgDn", "Left", "Up", "Right", "Down", "Delete":
				sendKey := "{" key "}"
				this.CancelToken(sendkey)
			case "NumpadHome", "NumpadEnd", "NumpadPgUp", "NumpadPgDn", "NumpadLeft", "NumpadUp", "NumpadRight", "NumpadDown", "NumpadDel":
				sendkey := "{" RegExReplace(key, "Numpad") "}"
				this.CancelToken(sendkey)
			case "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0":
				sendkey := RegExReplace(key, "Numpad")
				this.AddToToken(sendkey)
			case "NumpadDot":
				sendkey := ""
				this.SendToken(".")
			case "NumpadDiv":
				sendkey := ""
				this.SendToken("/")
			case "NumpadMult":
				sendkey := ""
				this.SendToken("*")
			case "NumpadSub":
				sendkey := ""
				this.SendToken("-")
			case "NumpadAdd":
				sendkey := ""
				this.SendToken("+")
			case "Backspace":
				sendKey := "{" key "}"
				this.RemoveKeyFromToken()
			case "LShift", "RShift", "LControl", "RControl", "LAlt", "RAlt", "LWin", "RWin", "CapsLock":
				sendKey := ""
			default:
				sendKey := "{" key "}"
				;ToolTip, % "Unknown key: " key
				;SetTimer, ClearToolTipEngine, -1500
				this.SendToken("{" key "}")
		} 
		; Send, % sendKey
		if (sendKey != ""){
			this.logEvent(3, "Passthrough: {Blind}" sendKey)
			SendInput, % "{Blind}" sendKey
			;Msgbox, % "Sent {Blind}" sendKey
		}
		; sendKey is blanked out, so be sure to check on the original key 
		if ((this.keyboard.AutoPunctuationSent) and (Instr(this.keyboard.EndKeys_hard, key))) {
			this.logEvent(4, "Adding trailing autospace back after deletion with " sendKey)
			Send, {Space}
		}
		this.keyboard.AutoPunctuationSent := false
	}
	
	getModifierStates()	{
		state := ""
		if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")	{
			state .= "#"
		}

		if GetKeyState("LControl", "P")	{
			state .= "^"
		}

		if GetKeyState("LAlt", "P")	{
			state .= "!"
		}

		if GetKeyState("Shift", "P")	{
			state .= "+"
		}
		return state
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
		}
	}

	AddToToken(key) {
		; Accumulate this letter
		if ((GetKeyState("Shift", "P")) or (GetKeyState("CapsLock", "T"))) {
			StringUpper key, key
		} 
		if (GetKeyState("Control", "P")) {
			this.logEvent(3, "Cancelling key due to Control character")
			key := ""
			this.keyboard.AutoSpaceSent := false 
		} 
		this.keyboard.Token .= key
		this.JoinChord(key)
		this.coachAhead(true)
	}

	RemoveKeyFromToken() {
		; This is a backspace
		if (GetKeyState("Control", "P")) {
			this.logEvent(3, "Cancelling token due to Control backspace")
			this.input_text_buffer := ""
			this.keyboard.Token := ""
		} else if (not StrLen(this.keyboard.Token)) {
			; If we are deleting things written before this token, we have to take from the buffer
			this.keyboard.Token := RegExReplace(this.input_text_buffer, "^.*\W(\w*.)$", "$1")
			this.input_text_buffer := SubStr(this.input_text_buffer, 1, (StrLen(this.input_text_buffer) - (StrLen(this.keyboard.Token) + 0)))
			this.logEvent(3, "Inserting last word from input text buffer as token: " this.keyboard.Token)
			this.keyboard.Token := SubStr(this.keyboard.Token, 1, (StrLen(this.keyboard.Token) - 1))
		} else {
			this.keyboard.Token := SubStr(this.keyboard.Token, 1, (StrLen(this.keyboard.Token) - 1))
		}
		; We have to reset the deletion of the auto space, or it will double delete
		this.keyboard.AutoSpaceSent := false
		this.coachAhead(true)
	}

	CancelToken(key) {
		this.logEvent(3, "Cancelling token '" this.keyboard.Token "' with '" key " and resyncing modifier state")
		; Send the empty key through to clear the input buffer
		this.keyboard.Token := ""
		this.input_text_buffer := ""
		this.keyboard.AutoSpaceSent := false
		this.ExpandInput(this.keyboard.Token, key, "", (A_TickCount - this.keyboard.TokenStartTicks))
		this.coachAhead(false)
	}

	SendToken(key) {
		Critical 
		this.logEvent(3, "Sending critical token '" this.keyboard.Token "' with '" key "': AutoSpaceSent is " this.keyboard.AutoSpaceSent)
		; Send through a valid qwerd because an end character was typed 
		if (this.keyboard.AutoSpaceSent) {
			; We sent a space after sending a chord. 
			if (not this.keyboard.Token) {
				; if this is a bare end key, then we need to delete that autospace
				this.logEvent(4, "Deleting autospace and setting autopunctuation")
				Send, {Backspace}
				this.keyboard.AutoPunctuationSent := true
			}
		}
        this.ResyncModifierKeys()
        ; Bug in 1.1.32.00 causes shift key to stick
		if (not (GetKeyState("Shift", "P"))) {
			Send, {LShift up}{RShift up}
		}
		this.ExpandInput(this.keyboard.Token, key, "", (A_TickCount - this.keyboard.TokenStartTicks))
		if (not this.keyboard.ScriptCalled) {
			; Now send the end character 
			Send, % "{Blind}" key
		} else {
			this.keyboard.ScriptCalled := false
		}
		this.keyboard.Token := ""
		this.keyboard.TokenStartTicks := A_TickCount
		this.keyboard.AutoSpaceSent := false
		; SetTimer, ClearToolTipEngine, -1500
		Critical Off 
		this.coachAhead(false)
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
        ; Capturing this in order to have a bakp 
        this.keyboard.ChordPressStartTicks := A_TickCount
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
            if (chordWindow == 0) {
                ; If the system gets overloaded it will send all the key releases at once. This will keep chordWindow from being null
                chordWindow := A_TickCount - this.keyboard.ChordPressStartTicks
            }
			if ((StrLen(this.keyboard.Token) >= this.map.minimumChordLength) 
				and (chordWindow > 0) 
				and (chordWindow < this.keyboard.ChordReleaseWindows[StrLen(this.keyboard.Token)]) 
				and (StrLen(this.keyboard.Token) = this.keyboard.MaxChordLength)) {
				; The time is quick enough to call a chord 
				this.logEvent(2, "ChordWindow: completed " this.keyboard.Token " in " chordWindow "ms against allowed " this.keyboard.ChordReleaseWindows[StrLen(this.keyboard.Token)])
				this.keyboard.ChordLength := 0
				this.keyboard.MaxChordLength := 0
				this.SendChord()
			} else {
				; Too slow. Let this be serial input
				this.logEvent(2, "ChordWindow: too short or timed out " this.keyboard.Token " in " chordWindow "ms against " this.keyboard.ChordReleaseWindow " and chord is complete is " (StrLen(this.keyboard.Token) = this.keyboard.MaxChordLength))
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
		Critical
		; Send through a possible chord
		chord := this.map.AlphaOrder(this.keyboard.Token)
		if ((GetKeyState("Shift", "P")) or (GetKeyState("CapsLock", "T"))) {
			StringUpper, chord, chord
		}
		if (this.map.chords.item(chord).word) {
			; Sleep long enough to see whether another key is pressed
			; Sleep, this.keyboard.ChordReleaseWindow
			if (not this.keyboard.ChordLength) {
				this.logEvent(2, "Chord: allowed because no other key was struck")
				; The sorted input is a valid chord, so push it as input
				this.logEvent(4, "Chord " chord " found for " this.map.chords.item(chord).word)
				this.ExpandInput(chord, "{Chord}", "", (A_TickCount - this.keyboard.TokenStartTicks))
				if (not this.keyboard.ScriptCalled) {
					Send, {Space}
					; Mark that we sent this as a chord, so we know we need to send a backspace before the next end char
					this.keyboard.AutoSpaceSent := true
				} else {
					this.keyboard.ScriptCalled := false
				}
				; Reset the input token 
				this.keyboard.Token := ""
				this.keyboard.TokenStartTicks := A_TickCount
			} else {
				this.logEvent(2, "Chord: aborted because another key was struck")
			}
		} else {
			this.logEvent(4, "Chord " chord " not found. Allow input to complete in serial fashion")
		}
		Critical Off 
		this.coachAhead(false)
	}

	ExpandInput(input_text, key, mods, ticks) {
		this.logEvent(2, "Expanding |" input_text "|" key "|" mods "|" ticks "|" )
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
			if (not (GetKeyState("LControl", "P") or GetKeyState("RControl", "P"))) {
				; Success 
				; Coach the found qwerd
				this.pushCoaching(this.map.chords.item(inbound.token), true, false, false, key, 1)
				;this.pushPenStroke(this.map.chords.item(inbound.token), "blue")
				this.pushDashboardQwerd(this.map.chords.item(inbound.token), "blue")
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
			if (not (GetKeyState("LControl", "P") or GetKeyState("RControl", "P"))) {
				; Success 
				; Coach the found qwerd
				this.pushCoaching(this.map.qwerds.item(inbound.token), true, false, false, key, 0)
				;this.pushPenStroke(this.map.qwerds.item(inbound.token), "blue")
				this.pushDashboardQwerd(this.map.qwerds.item(inbound.token), "blue")
				; "Push Input" is where the magic happens on screen
				final_characters_count := this.pushInput(inbound.token, this.map.qwerds.item(inbound.token).word, key)
			} else {
				this.logEvent(2, "Control key down on match, so don't expand " inbound.token)
				; The control key was down, so don't expand, still send the end char, and count the chars typed
				final_characters_count := StrLen(inbound.token) + 1
			}
		} else {
			; This buffered input was not a special character, nor a qwerd
			this.logEvent(1, "Passing " inbound.token)
			this.logEvent(4, "Input text was " input_text)
			if (input_text) {
				final_characters_count := StrLen(inbound.token) + 1
				if (this.map.hints.item(inbound.token).hint) {
					this.pushCoaching(this.map.hints.item(inbound.token), false, true, false, key, 0)
					;this.pushPenStroke(this.map.hints.item(inbound.token), "red")
					ink := (StrLen(this.map.hints.item(inbound.token).word) > StrLen(this.map.hints.item(inbound.token).qwerd)) ? "red" : "blue"
         ; Msgbox, % "comparing "  " to "  " I get " ink 
					this.pushDashboardQwerd(this.map.hints.item(inbound.token), ink)
		
					;;; Hintable
					this.logEvent(2, "Matched a hint " this.map.hints.item(inbound.token).hint)
				} else {
					; This is an unknown word and qwerd. Send it to coaching, but only if it's not too strange
					if (not inbound.isSensitive) {
						this.nullQwerd.word := inbound.token
						this.pushCoaching(this.nullQwerd, false, false, true, key, (StrLen(inbound.token)))
						;this.pushPenStroke(this.nullQwerd, "purple")
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
        this.ResyncModifierKeys()
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
		; Adding ";" to the check here makes :q not expand. That's important to a vim user like me. 
		inbound.isCode := (((inbound.preceding_char == " ") or (inbound.preceding_char == "")) and ((inbound.initial_end_char) and (InStr("-:;/", inbound.initial_end_char))))
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
	
	;pushPenStroke(qwerd, ink) {
;		penAction := new PenEvent(qwerd.form, qwerd.qwerd, qwerd.word, ink)
;		this.penQueue.enqueue(penAction)
;		this.logEvent(4, "Enqueued pen action '" penAction.form "'")
;	}
	
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
