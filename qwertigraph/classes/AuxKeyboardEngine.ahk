
class AuxKeyboardEngine
{
	logQueue := new Queue("AuxEngineQueue")
	logVerbosity := 3
	enabled := true

	__New() {
		local
		this.engine := ""
		this.enabled := true
		this.auxmap := "classes\AuxKeymapFull.csv"
		
		this.keymap := {}
		this.keymapCount := 0
	
		Loop,Read, % this.auxmap  
		{
			NumLines:=A_Index-1
			if (A_Index = 1) {
				; We do nothing with the title row
				Continue 
			}
			fields := StrSplit(A_LoopReadLine, ",")
			this.keymap["" . fields[1]] := fields[2]
			this.logEvent(4, "Setting " fields[1] " to " fields[2])
			this.keymapCount += 1
			if (StrLen(fields[1]) = 2) {
				arr := StrSplit(fields[1]) 
				this.keymap["" . arr[2] . arr[1]] := fields[2]
			}
		}
		this.logEvent(2, "Loaded from " this.auxmap " " this.keymapCount " characters with " this.keymap["1"])
		
		this.Start()
	}
	Start() {
		this.logEvent(2, "Auxilliary Keyboard Engine started with " this.keymap.MaxIndex() " keys")
		this.enabled := true
	}
	Stop() {
		this.logEvent(2, "Auxilliary Keyboard Engine stopped")
		this.enabled := false 
	}
	Flush() {
		this.chord := ""
	}
	
	RemapKey(key) {
		bareKey := RegExReplace(key, "Numpad")
		if (this.keymap["" . bareKey] and this.enabled) {
			this.logEvent(4, "Matched valid keymap")
			rekey := this.keymap["" . bareKey]
			this.chord .= bareKey
		} else {
			this.logEvent(4, "No valid keymap")
			rekey := bareKey
		}
		this.logEvent(2, "Remapping " key " as " bareKey " to " rekey " and chord is " this.chord)
		Return rekey
	}
	LeaveChord(key) {
		; The complexity here is that on a successful chord, the Aux Keyboard has already sent "transition" characters 
		; The transition characters need to be unsent from the screen
		; Then they need to be unsent from the token
		; Then the correct character then needs to be forced to the screen
		; Finally, the correct character needs to be send to the token
		this.logEvent(4, "Testing leaving chord with " key " against " this.chord)
		chordLength := StrLen(this.chord)
		if (this.enabled and (chordLength > 1)) {
			if (this.keymap["" . this.chord]) {
				this.logEvent(3, "Matched chord " this.chord " as " this.keymap["" . this.chord])
				; Unsend all characters from screen
				Send, {Backspace %chordLength%}
				; Unsend all characters from token
				this.engine.keyboard.Token := SubStr(this.engine.keyboard.Token, 1, (StrLen(this.keyboard.Token) - chordLength))
				; Send to screen 
				Send, % this.keymap["" . this.chord]
				; Send to token
				this.engine.keyboard.Token .= this.keymap["" . this.chord]
			}
		}
		; Clear the chord buffer for a fresh start 
		this.Flush()
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

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("aux",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
