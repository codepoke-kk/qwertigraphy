
class AuxKeyboardEngine
{
	logQueue := new Queue("AuxEngineQueue")
	logVerbosity := 4
	enabled := true

	__New() {
		local
		this.engine := ""
		this.auxmap := "classes\AuxKeymapFull.csv"
		
		this.keymap := {}
		this.keymapCount := 0
		this.keysdown := 0
		this.enabled := true
		this.shifted := ""
		this.controlled := ""
		this.alted := ""
		this.winned := "" 
		this.numlocked := true 
		SetNumLockState , % this.numlocked
	
		Loop,Read, % this.auxmap  
		{
			NumLines:=A_Index-1
			if (A_Index = 1) {
				; We do nothing with the title row
				Continue 
			}
			mapfields := StrSplit(A_LoopReadLine, ",")
			if (mapfields[2] = "{Comma}") {
				mapfields[2] := ","
			} else if (mapfields[2] = "{Semicolon}") {
				mapfields[2] := ";"
			}
			keyfields := StrSplit(mapfields[1], ";")
			this.keymap[mapfields[1]] := mapfields[2]
			this.logEvent(4, "Setting " mapfields[1] " to " mapfields[2])
			this.keymapCount += 1
			if (keyfields.MaxIndex() = 1) {
				this.keymap[keyfields[1]] := mapfields[2]
			} else if (keyfields.MaxIndex() = 2) {
				this.keymap[keyfields[1] . keyfields[2]] := mapfields[2]
				this.keymap[keyfields[2] . keyfields[1]] := mapfields[2]
			} else if (keyfields.MaxIndex() = 3) {
				this.keymap[keyfields[1] . keyfields[2] . keyfields[3]] := mapfields[2]
				this.keymap[keyfields[1] . keyfields[3] . keyfields[2]] := mapfields[2]
				this.keymap[keyfields[2] . keyfields[1] . keyfields[3]] := mapfields[2]
				this.keymap[keyfields[2] . keyfields[3] . keyfields[1]] := mapfields[2]
				this.keymap[keyfields[3] . keyfields[1] . keyfields[2]] := mapfields[2]
				this.keymap[keyfields[3] . keyfields[2] . keyfields[1]] := mapfields[2]
			}
		}
		this.logEvent(2, "Loaded from " this.auxmap " " this.keymapCount " characters with " this.keymap["Numpad0"])
		
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
		this.shifted := ""
		this.controlled := ""
		this.alted := ""
		this.winned := "" 
		this.keysdown := 0
	}
	
	RemapKey(key) {
		if (this.enabled) {
			this.keysdown += 1
			if (this.keymap[key] = "{Reset}") { 
				rekey := ""
				this.logEvent(4, "Reset key down")
			} else if ((this.keymap[key] = "{LShift}") or (this.keymap[key] = "{RShift}")) {
				this.shifted := "+" 
				rekey := ""
				this.logEvent(4, "Shift key down")
			} else if (this.keymap[key] = "{Control}") {
				this.controlled := "^" 
				rekey := ""
				this.logEvent(4, "Control key down")
			} else if (this.keymap[key] = "{Alt}") {
				this.alted := "!" 
				rekey := ""
				this.logEvent(4, "Alt key down")
			} else if (this.keymap[key] = "{Win}") {
				this.winned := "#" 
				rekey := ""
				this.logEvent(4, "Win key down")
			} else if (this.keymap[key]) {
				this.logEvent(4, "Matched valid keymap for " key)
				rekey := ""
				this.chord .= "" . key
				this.logEvent(2, "Swallowing " key " into chord as " this.chord)
			} else {
				rekey := RegExReplace(key, "Numpad")
				this.logEvent(2, "Forwarding unmatched " key " as " rekey)
			}
		} else {
			rekey := RegExReplace(key, "Numpad")
			this.logEvent(2, "Forwarding unmatched " key " as " rekey)
		}
		Return rekey
	}
	LeaveChord(key) {
		this.logEvent(4, "Testing leaving chord with " key " against " this.chord)
		Critical 
		chordLength := StrLen(this.chord)
		if (this.enabled) {
			if (chordLength and this.keymap[this.chord]) {
				this.logEvent(3, "Matched chord " this.chord " as " this.keymap[this.chord])
				; Send to token
				if ((StrLen(this.keymap[this.chord]) = 1) and (not RegExMatch(this.keymap[this.chord], "[a-zA-Z0-9]"))) {
					this.logEvent(3, "Chord is non-text, sending and ending")
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.chord]
				} else if (this.keymap[this.chord] = "{Backspace}") {
					this.logEvent(3, "Chord is backspace. Shortening token by 1")
					this.engine.RemoveKeyFromToken()
					; Send to screen 
					Send, % this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord]
				} else if (not RegExMatch(this.keymap[this.chord],"\{")) { 
					this.logEvent(3, "Chord is not a control character. Adding " this.keymap[this.chord] " to token")
					if (not this.shifted) {
						this.engine.keyboard.Token .= this.keymap[this.chord]
					} else {
						StringUpper, upperKey, % this.keymap[this.chord]
						this.engine.keyboard.Token .= upperKey
					} 
					; Send to screen 
					Send, % this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord]
				} else {
					this.logEvent(3, "Chord is a control character. Sending token with " this.keymap[this.chord])
					this.engine.SendToken(this.keymap[this.chord])
				}
			} else if (this.keysdown) {
				; We can only watch for this on the first key up. 
				; If a modifier key is not the first key up, then this will send the modifier's value if we reset and keep watching 
				if ((this.keymap[key] = "{LShift}") or (this.keymap[key] = "{RShift}")) {
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.keymap[key]]
					this.logEvent(4, "Shift key sent bare")
				} else if (this.keymap[key] = "{Control}") {
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.keymap[key]]
					this.logEvent(4, "Control key sent bare")
				} else if (this.keymap[key] = "{Alt}") {
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.keymap[key]]
					this.logEvent(4, "Alt key sent bare")
				} else if (this.keymap[key] = "{Win}") {
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.keymap[key]]
					this.logEvent(4, "Win key sent bare")
				} else if (this.keymap[key] = "{Reset}") {
					this.logEvent(3, "Chord is Reset. Cancelling token and sending " this.keymap[this.keymap[key]])
					this.engine.CancelToken(this.keymap[key])
					this.numlocked := !this.numlocked
					SetNumLockState , % this.numlocked
				} 
			}
		}
		; Clear the chord buffer for a fresh start 
		this.Flush()
		Critical Off
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
