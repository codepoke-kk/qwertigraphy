; At this point, ctrl-click works, which is nice. 
; Current bug: Ctrl-Click also send "Enter" upon release

class AuxKeyboardEngine
{
	logQueue := new Queue("AuxEngineQueue")
	logVerbosity := 4
	enabled := true
    dashboard := ""

	__New() {
		local
		this.engine := ""
		this.auxmap := "classes\AuxKeymapFull.csv"
		
		this.keymap := {}
		this.keymapCount := 0
		this.keysdown := 0
        this.lastkey := ""
        this.lastkeycount := 0
		this.enabled := true
		this.layer := ""
        this.layerlocked := ""
		this.caplocked := ""
        this.winlocked := ""
		this.shifted := ""
		this.controlled := ""
		this.alted := ""
		this.winned := "" 
		this.numlocked := true 
		SetNumLockState , % this.numlocked
        
        this.NumpadShiftedRemap := {}
        this.NumpadShiftedRemap["NumpadHome"] := "Numpad7"
        this.NumpadShiftedRemap["NumpadUp"] := "Numpad8"
        this.NumpadShiftedRemap["NumpadPgUp"] := "Numpad9"
        this.NumpadShiftedRemap["NumpadRight"] := "Numpad6"
        this.NumpadShiftedRemap["NumpadPgDn"] := "Numpad3"
        this.NumpadShiftedRemap["NumpadDown"] := "Numpad2"
        this.NumpadShiftedRemap["NumpadEnd"] := "Numpad1"
        this.NumpadShiftedRemap["NumpadLeft"] := "Numpad4"
        this.NumpadShiftedRemap["NumpadClear"] := "Numpad5"
        this.NumpadShiftedRemap["NumpadIns"] := "Numpad0"
        this.NumpadShiftedRemap["NumpadDel"] := "NumpadDot"
	
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
		
		; this.Start()
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
        this.logEvent(2, "Auxilliary Keyboard Engine flushed")
		this.chord := ""
		this.shifted := ""
		this.controlled := ""
		this.alted := ""
		this.winned := "" 
		this.keysdown := 0
	}
	
	RemapKey(key) {
		if (this.enabled) {
            this.logEvent(4, "Remapping " key)
            ; I have to override the desire of Windows to cancel numlock when shift is down 
            if (this.numlocked and this.NumpadShiftedRemap[key] ) {
                key := this.NumpadShiftedRemap[key]
                this.logEvent(4, "Double remapped key to " key " to override shift-cancels-numlock issue")
            } else {
                ; this.logEvent(4, "No double remap of " key " needed because state " GetKeyState("LShift") ", numlock " this.numlocked " and double remap of " this.NumpadShiftedRemap[key])
            }
            ; Don't count keys sent by "repeat key" by the OS when a key is held down
            if (key != this.lastkey) {
                ; Count the number of keys down
                this.keysdown += 1
                this.logEvent(4, "Incremented keysdown to " this.keysdown " because " key " != " this.lastkey)
                this.lastkey := key
            } else {
                this.lastkeycount += 1
                this.logEvent(4, "Incremented lastkeycount to " this.lastkeycount)
            }
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
                Send, {LShift down}
				rekey := ""
				this.logEvent(4, "Shift key down")
			} else if (this.keymap[key] = "{Tab}") {
				this.logEvent(4, "Matched valid keymap for " key " as " this.keymap[key])
				rekey := ""
                this.chord .= "" . key
				this.logEvent(2, "Swallowing " key " into chord as " this.chord)
			} else if (this.keymap[key] = "{Control}") {
				this.controlled := "^" 
                Send, {LControl down}
				rekey := ""
				this.logEvent(4, "Control key down")
			} else if (this.keymap[key] = "{Alt}") {
				Send, {LAlt down}
				this.alted := "!" 
				rekey := ""
				this.logEvent(4, "Alt key down")
			} else if (this.keymap[key] = "{Win}") {
				this.winned := "#" 
				Send, {LWin down}
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
			rekey := "{" . RegExReplace(key, "Numpad") . "}"
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
            this.logEvent(4, "keysdown is " this.keysdown ", key is " key ", and lastkey is " this.lastkey)
            if (this.numlocked and this.NumpadShiftedRemap[key] ) {
                key := this.NumpadShiftedRemap[key]
                this.logEvent(4, "Remapped key to " key " to override shift-numlock issue")
            }
			if (chordLength and this.keymap[this.chord]) {
				; We have a real chord. Now, which type?
				; Apply cap locking here
				if (this.caplocked) {
					this.shifted := "+"
				}
				if (this.winlocked) {
					this.winned := "#"
                    Send, {LWin down}
				}
				this.logEvent(3, "Matched chord " this.chord " as " this.keymap[this.chord])
				if ((StrLen(this.keymap[this.chord]) = 1) and (not RegExMatch(this.keymap[this.chord], "[a-zA-Z0-9]"))) {
					this.logEvent(3, "Chord is non-text, sending and ending")
					this.engine.listener.EndToken(this.keymap[this.chord])
					Send, % this.shifted . this.keymap[this.chord]
					this.ToggleLayerLock()
				} else if (this.keymap[this.chord] = "{Backspace}") {
					this.logEvent(3, "Chord is backspace. Shortening token by 1")
					this.engine.listener.RemoveKeyFromToken()
					; Send to screen 
					Send, % this.shifted this.keymap[this.chord]
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
				} else if (this.keymap[this.chord] = "{WinLock}") {
					this.logEvent(3, "Chord is WinLock. Setting.")
					if (this.winlocked = "set") {
						this.winlocked := ""
					} else if (this.winlocked = "once") {
						this.winlocked := "set"
					} else if (this.winlocked = "") {
						this.winlocked := "once"
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
					this.logEvent(3, "Chord is not an end character. Adding " this.keymap[this.chord] " to token")
					if (not this.shifted) {
                        this.engine.keyboard.Token .= this.keymap[this.chord]
					} else {
						StringUpper, upperKey, % this.keymap[this.chord]
						this.engine.keyboard.Token .= upperKey
					} 
					; Send to screen 
                    this.logEvent(3, "Sending to screen " this.keymap[this.chord]) " with " this.shifted 
					Send, % this.shifted . this.keymap[this.chord]
                    ; We need to cancel the token if we sent it as a control character 
                    if (this.controlled or this.alted or this.winned) {
                        this.logEvent(3, "Chord is modded. Cancelling existing token")
                        this.engine.listener.CancelToken("{Modded}")
                    }
					this.ToggleLayerLock()
				} else {
					this.logEvent(3, "Chord is an end character. Sending token " this.keymap[this.chord] " with " this.shifted . this.controlled . this.alted . this.winned)
					this.engine.listener.EndToken(this.shifted . this.keymap[this.chord])
					this.ToggleLayerLock()
				}
			} else if (this.keysdown) {
                ; If no chord or no match, then this is one or more control characters
				; We can only watch for this on the first key up. 
				; If a modifier key is not the first key up, then this will send the modifier's value if we reset and keep watching
                if (this.keysdown > 1) {
                    ; We have multiple control keys down, which means we are trying to modify one with the other 
                    this.logEvent(4, "Multiple bare control keys down and " key " coming up")
                    ;;;;;; I use redirection like this.keymap["_Alt"] so the keys can be remapped 
                    if (key = this.keymap["_Alt"] and GetKeyState(this.keymap["_Control"], "P") and GetKeyState(this.keymap["_LShift"], "P")){
                        ; control-alt-delete
                        this.engine.listener.EndToken("{Del}")
                        run taskmgr
                        this.logEvent(4, "Space, Control, and Esc keys down and Esc released so running task manager")
                    } else if (key = this.keymap["_Control"] and GetKeyState(this.keymap["_Alt"], "P") and GetKeyState(this.keymap["_LShift"], "P")){
                        ; control-shift-escape
                        this.engine.listener.EndToken("{Esc}")
                        Send, % "^+{Esc}"
                        this.logEvent(4, "Space, Control, and Esc keys down and Control released so sending bare as ^+{Esc}")
                    } else if (key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Control"], "P") and GetKeyState(this.keymap["_Alt"], "P")){
                        ; control-alt-end
                        this.engine.listener.EndToken("{End}")
                        Send, % "^!{End}"
                        this.logEvent(4, "Space, Control, and Esc keys down and Space released so sending bare as ^!{End}")
                    } else if ((key = this.keymap["_Alt"] and GetKeyState(this.keymap["_LShift"], "P")) or (key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Alt"], "P"))){
                        ; alt-space
                        this.engine.listener.EndToken("{Space}")
                        Send, % "{Space}"
                        this.logEvent(4, "Space and Control key sent bare as {Space}")
                    } else if ((key = this.keymap["_LShift"] and GetKeyState(this.keymap["_Control"], "P")) or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_LShift"], "P"))) {
                        ; shift-enter
                        this.controlled := ""
                        Send, {LControl up}
                        this.engine.listener.EndToken("+{Enter}")
                        this.logEvent(4, "LShift and Enter key sent bare as +{Enter}")
                    } else if (key = this.keymap["_RShift"] and GetKeyState(this.keymap["_Control"], "P")) {
                        ; control-backspace
                        ; Send, % "{Backspace}"
                        this.engine.listener.EndToken("{Backspace}")
                        this.logEvent(4, "BackSpace and Control key and BackSpace released first, so sent bare as ^{Backspace}")
                    } else if (key = this.keymap["_Control"] and GetKeyState(this.keymap["_RShift"], "P")) {
                        ; control-enter
                        ; This cannot be reached on my keyboard, due to ghosting. When NumpadDot is down, my keyboard also reports Numpad0 is down 
                        ; this.logEvent(4, "BackSpace and Control key and Enter released first, so sent bare as ^{Enter}")
                    } else if ((key = this.keymap["_Alt"] and GetKeyState(this.keymap["_Control"], "P")) or (key = this.keymap["_Control"] and GetKeyState(this.keymap["_Alt"], "P"))) {
                        ; alt-enter
                        this.engine.listener.EndToken("{Enter}")
                        Send, % "{Enter}"
                        this.logEvent(4, "Esc and Enter key sent bare as {Enter}")
                    } else {
                        this.logEvent(4, "No code for this entry")
                    }
                ; this.keysdown <= 1
				} else if ((this.keymap[key] = "{LShift}") or (this.keymap[key] = "{RShift}")) {
                    ; if only the control key is pressed, then we meant it as its bare character
                    ; but if the actual control key it represents is down, then we cannot cancel its control function 
                    if (not GetKeyState("LShift", "P")) {
                        Send, {LShift up}
                    }
                    if (this.lastkeycount < 2) {
                        if (not this.keymap[this.keymap[key]] = "{Backspace}") {
                            this.engine.listener.EndToken(this.keymap[this.chord])
                        } else {
                            this.engine.listener.RemoveKeyFromToken()
                        }
                        Send, % this.keymap[this.keymap[key]]
                        this.logEvent(4, "Shift key sent bare as " this.keymap[this.keymap[key]] " with " this.controlled . this.alted . this.winned)
                    } else {
                        this.logEvent(4, "Shift key not sent due to repeat key of " this.lastkeycount)
                    }
				} else if (this.keymap[key] = "{Control}") {
                    this.logEvent(4, "Found control key coming up")
                    ; if only the control key is pressed, then we meant it as its bare character
                    ; but if the actual control key it represents is down, then we cannot cancel its control function 
                    if (not GetKeyState("LControl", "P")) {
                        this.logEvent(4, "Lifting LControl")
                        Send, {LControl up}
                    } else {
                        this.logEvent(4, "Not lifting LControl because " GetKeyState("LControl", "P"))
                    }
                    if (this.lastkeycount < 2) {
                        this.engine.listener.EndToken(this.shifted . this.keymap[this.chord])
                        Send, % this.shifted . this.keymap[this.keymap[key]]
                        this.logEvent(4, "Control key sent bare as " this.shifted . this.keymap[this.keymap[key]])
                    } else {
                        this.logEvent(4, "Shift key not sent due to repeat key of " this.lastkeycount)
                    }
				} else if (this.keymap[key] = "{Alt}") {
                    ; if only the control key is pressed, then we meant it as its bare character
                    ; but if the actual control key it represents is down, then we cannot cancel its control function 
                    if (not GetKeyState("LAlt", "P")) {
                        Send, {LAlt up}
                    }
                    if (this.lastkeycount < 2) {
                        Send, u
                        Send, % this.shifted . this.keymap[this.keymap[key]]
                        this.engine.listener.EndToken(this.keymap[this.keymap[key]])
                        this.logEvent(4, "Alt key sent bare as " this.shifted . this.keymap[this.keymap[key]])
                    } else {
                        this.logEvent(4, "Shift key not sent due to repeat key of " this.lastkeycount)
                    }
				} else if (this.keymap[key] = "{Win}") {
                    ; if only the control key is pressed, then we meant it as its bare character
                    ; but if the actual control key it represents is down, then we cannot cancel its control function 
                    if (not GetKeyState("LWin", "P")) {
                        Send, {LWin up}
                    }
                    if (this.lastkeycount < 2) {
                        this.engine.listener.EndToken(this.shifted . this.keymap[this.chord])
                        Send, % this.shifted . this.keymap[this.keymap[key]]
                        this.logEvent(4, "Win key sent bare as " this.shifted . this.controlled . this.alted . this.keymap[this.keymap[key]])
                    } else {
                        this.logEvent(4, "Shift key not sent due to repeat key of " this.lastkeycount)
                    }
				} else if (this.keymap[key] = "{Reset}") {
					this.logEvent(3, "Chord is Reset. Cancelling token and sending " this.keymap[this.keymap[key]])
					this.engine.listener.EndToken(this.keymap[key])
					this.numlocked := !this.numlocked
					SetNumLockState , % this.numlocked
				} 
			} 
            
            this.logEvent(4, "Key up after all keys up")
            ; We must cancel all control character keydowns 
            if ((this.keymap[key] = "{LShift}") or (this.keymap[key] = "{RShift}")) {
                if (not GetKeyState("LShift", "P")) {
                    Send, {LShift up}
                }
            } else if (this.keymap[key] = "{Control}") {
                this.logEvent(4, "Control Key coming up after all keys up")
                if (not GetKeyState("LControl", "P")) {
                    Send, {LControl up}
                }
            } else if (this.keymap[key] = "{Alt}") {
                if (not GetKeyState("LAlt", "P")) {
                    Send, {LAlt up}
                }
            } else if (this.keymap[key] = "{Win}") {
                if (not GetKeyState("LWin", "P")) {
                    Send, {LWin up}
                }
            }
            
            if (GetKeyState("LWin") and (not GetKeyState("LWin", "P"))) {
                this.logEvent(4, "Winned, so sending key up")
                Send, {LWin up}
            }
            
            ; I should probably make this a queue solution, but I need it now 
            if (this.dashboard) {
                this.dashboard.auxKeyboardState := this.winned . this.shifted . this.controlled . this.alted . this.layer
            }
            
            this.lastkey := ""
            this.lastkeycount := 0
				
		}
		; Clear the chord buffer for a fresh start 
		this.Flush()
		Critical Off
	}
    
    ToggleLayerLock() {
        if (this.caplocked = "once") {
            this.caplocked := ""
            this.logEvent(4, "Cancelled capslock after once")
        }
        if (this.winlocked = "once") {
            this.winlocked := ""
            this.logEvent(4, "Cancelled winlock after once")
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
