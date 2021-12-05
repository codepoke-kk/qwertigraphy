
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
		this.layer := ""
        this.layerlocked := ""
		this.caplocked := ""
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
            this.logEvent(4, "Working " key)
			; Count the number of keys down, though we only care if it's 1 or greater 
			this.keysdown += 1
			; Implement layers by prepending a layer marker to every one of the 9 digit keys (not the zero key)
			if (RegExMatch(key, "^Numpad[1-9]$")) {
				key := this.layer . key
			}
			; We will mark any and every mod key for its mod value 
			; These, therefore, can never be used in a chord
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
				Send, {LAlt down}
				this.alted := "!" 
				rekey := ""
				this.logEvent(4, "Alt key down")
			} else if (this.keymap[key] = "{Win}") {
				this.winned := "#" 
				rekey := ""
				this.logEvent(4, "Win key down")
			} else if (this.keymap[key]) {
				; Special keys are done. If we did not find anything, and this is a mapped key, then add it to the chord
				this.logEvent(4, "Matched valid keymap for " key)
				rekey := ""
                this.chord .= "" . key
				this.logEvent(2, "Swallowing " key " into chord as " this.chord)
			} else {
				; If we don't care what this is, then strip the "numpad" from it and send it back to be handled as a normal key 
				rekey := RegExReplace(key, "Numpad")
				this.logEvent(2, "Forwarding enabled but unmatched " key " as " rekey)
			}
		} else {
			; If we are disabled then strip the "numpad" from it and send it back to be handled as a normal key 
			rekey := RegExReplace(key, "Numpad")
			this.logEvent(2, "Forwarding disabled and unmatched " key " as " rekey)
		}
		Return rekey
	}
	LeaveChord(key) {
		; By and large, we send things upon the release of the first key, then reset everything so we ignore subsequent key releases 
		this.logEvent(4, "Testing leaving chord with " key " against " this.chord)
		; If this is not critical, this method can be called simultaneously by multiple key releases from the same chord 
		Critical 
		chordLength := StrLen(this.chord)
		if (this.enabled) {
			if (chordLength and this.keymap[this.chord]) {
				; We have a real chord. Now, which type 
				; Apply cap locking here
				if (this.caplocked) {
					this.shifted := "+"
				}
				this.logEvent(3, "Matched chord " this.chord " as " this.keymap[this.chord])
				if ((StrLen(this.keymap[this.chord]) = 1) and (not RegExMatch(this.keymap[this.chord], "[a-zA-Z0-9]"))) {
					this.logEvent(3, "Chord is non-text, sending and ending")
					this.engine.SendToken(this.keymap[this.chord])
					Send, % this.keymap[this.chord]
					this.ToggleLayerLock()
				} else if (this.keymap[this.chord] = "{Backspace}") {
					this.logEvent(3, "Chord is backspace. Shortening token by 1")
					this.engine.RemoveKeyFromToken()
					; Send to screen 
					Send, % this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord]
					this.ToggleLayerLock()
				} else if (this.keymap[this.chord] = "{CapLock}") {
					this.logEvent(3, "Chord is CapLock. Setting.")
					if (this.caplocked = "set") {
						this.caplocked := ""
					} else if (this.caplocked = "once") {
						this.caplocked := "set"
					} else if (this.caplocked = "") {
						this.caplocked := "once"
					}
				} else if (this.keymap[this.chord] = "{Layer_Numbers}") {
					this.logEvent(3, "Chord is Numbers Layer. Setting.")
					if (this.layer = "Ln") {
                        if (this.layerlocked = "once") {
                            this.layerlocked := "set"
                        } else {
                            this.layer := ""
                            this.layerlocked := ""
                        }
					} else {
						this.layer := "Ln"
                        this.layerlocked := "once"
					}
                    this.logEvent(4, "Layer is " this.layer " and lock state is " this.layerlocked)
				} else if (this.keymap[this.chord] = "{Layer_Symbols}") {
					this.logEvent(3, "Chord is Symbols Layer. Setting.")
					if (this.layer = "Ls") {
                        if (this.layerlocked = "once") {
                            this.layerlocked := "set"
                        } else {
                            this.layer := ""
                            this.layerlocked := ""
                        }
					} else {
						this.layer := "Ls"
                        this.layerlocked := "once"
					}
                    this.logEvent(4, "Layer is " this.layer " and lock state is " this.layerlocked)
				} else if (not RegExMatch(this.keymap[this.chord],"\{")) { 
					this.logEvent(3, "Chord is not a control character. Adding " this.keymap[this.chord] " to token")
					if (not this.shifted) {
                        this.engine.keyboard.Token .= this.keymap[this.chord]
					} else {
						StringUpper, upperKey, % this.keymap[this.chord]
						this.engine.keyboard.Token .= upperKey
					} 
					; Send to screen 
                    this.logEvent(3, "Sending to screen " this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord])
					Send, % this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord]
                    ; We need to cancel the token if we sent it as a control character 
                    if (this.controlled or this.alted or this.winned) {
                        this.logEvent(3, "Chord is modded. Cancelling existing token")
                        this.engine.CancelToken("{Modded}")
                    }
					this.ToggleLayerLock()
				} else {
					this.logEvent(3, "Chord is a control character. Sending token with " this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord])
					this.engine.SendToken(this.shifted . this.controlled . this.alted . this.winned . this.keymap[this.chord])
					this.ToggleLayerLock()
				}
			} else if (this.keysdown) {
                ; If no chord or no match
				; We can only watch for this on the first key up. 
				; If a modifier key is not the first key up, then this will send the modifier's value if we reset and keep watching
                if (this.keysdown > 1) {
                    ; We have multiple control keys down, which means we are trying to modify one with the other 
                    this.logEvent(4, "Multiple bare control keys down")
                    ;;;;;; I use redirection like this.keymap["_Alt"] so the keys can be remapped 
                    if ((key = this.keymap["_Alt"] and GetKeyState(this.keymap["_Control"], "P") and GetKeyState(this.keymap["_LShift"], "P")) 
                            or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_Alt"], "P") and GetKeyState(this.keymap["_LShift"], "P"))
                            or (key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Control"], "P") and GetKeyState(this.keymap["_Alt"], "P"))){
                        ; control-shift-escape
                        this.engine.SendToken("^+{Esc}")
                        Send, % "^+{Esc}"
                        this.logEvent(4, "Space, Control, and Esc keys sent bare as ^+{Esc}")
                    } else if ((key = this.keymap["_Alt"] and GetKeyState(this.keymap["_LShift"], "P")) or (key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Alt"], "P"))){
                        ; alt-space
                        this.engine.SendToken("!{Space}")
                        Send, % "!{Space}"
                        this.logEvent(4, "Space and Control key sent bare as !{Space}")
                    } else if ((key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Control"], "P")) or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_LShift"], "P"))) {
                        ; control-enter
                        ; Windows default here is to pop up a choice dialog, but I'm using this to cancel tokens
                        this.engine.CancelToken("^{Enter}")
                        ; Send, % "{LControl down}" 
                        Send, % "{Enter}"
                        ; Send, % "{LControl up}"
                        this.logEvent(4, "LSpace, and Control key sent bare as ^{Enter}")
                    } else if ((key = this.keymap["_RShift"] and GetKeyState(this.keymap["_Control"], "P")) or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_RShift"], "P"))) {
                        ; shift-enter
                        ; Send, % "+{Enter}"
                        this.engine.SendToken("+{Enter}")
                        this.logEvent(4, "RSpace and Enter key sent bare as +{Enter}")
                    } else if ((key = this.keymap["_Alt"] and GetKeyState(this.keymap["_Control"], "P")) or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_Alt"], "P"))) {
                        ; alt-enter
                        this.engine.SendToken("!{Enter}")
                        Send, % "!{Enter}"
                        this.logEvent(4, "Esc and Enter key sent bare as !{Enter}")
                    } else {
                        this.logEvent(4, "No code for this entry")
                    }
				} else if ((this.keymap[key] = "{LShift}") or (this.keymap[key] = "{RShift}")) {
					if (not this.keymap[this.keymap[key]] = "{Backspace}") {
						this.engine.SendToken(this.controlled . this.alted . this.winned .this.keymap[this.chord])
					} else {
						this.engine.RemoveKeyFromToken()
					}
					Send, % this.controlled . this.alted . this.winned . this.keymap[this.keymap[key]]
					this.logEvent(4, "Shift key sent bare as " this.controlled . this.alted . this.winned . this.keymap[this.keymap[key]])
				} else if (this.keymap[key] = "{Control}") {
					this.engine.SendToken(this.shifted . this.alted . this.winned . this.keymap[this.chord])
					Send, % this.shifted . this.alted . this.winned . this.keymap[this.keymap[key]]
					this.logEvent(4, "Control key sent bare as " this.shifted . this.alted . this.winned . this.keymap[this.keymap[key]])
				} else if (this.keymap[key] = "{Alt}") {
					this.engine.SendToken(this.shifted . this.controlled . this.winned . this.keymap[this.chord])
					Send, % this.shifted . this.controlled . this.winned . this.keymap[this.keymap[key]]
					this.logEvent(4, "Alt key sent bare as " this.shifted . this.controlled . this.winned . this.keymap[this.keymap[key]])
				} else if (this.keymap[key] = "{Win}") {
					this.engine.SendToken(this.shifted . this.controlled . this.alted . this.keymap[this.chord])
					Send, % this.shifted . this.controlled . this.alted . this.keymap[this.keymap[key]]
					this.logEvent(4, "Win key sent bare as " this.shifted . this.controlled . this.alted . this.keymap[this.keymap[key]])
				} else if (this.keymap[key] = "{Reset}") {
					this.logEvent(3, "Chord is Reset. Cancelling token and sending " this.keymap[this.keymap[key]])
					this.engine.CancelToken(this.keymap[key])
					this.numlocked := !this.numlocked
					SetNumLockState , % this.numlocked
				} 
			}
			if (this.keymap[key] = "{Alt}") {
				Send, {LAlt up}
			}
				
		}
		; Clear the chord buffer for a fresh start 
		this.Flush()
		Critical Off
	}
    
    ToggleLayerLock() {
        if (this.caplocked = "once") {
            this.caplocked := ""
        }
        if (this.layerlocked = "once") {
            this.layerlocked := ""
            this.layer := ""
            this.logEvent(4, "After cancel layer is " this.layer " and lock state is " this.layerlocked)
        }
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
