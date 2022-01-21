
Class Listener {

	__New(engine) {
		this.title := "Listener"
		this.name := "listener"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.ih := ""
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Start(accumulator) {
		this.logEvent(4, "Engine " this.title " starting")
		this.accumulator := accumulator
		
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
		this.logEvent(3, "Engine " this.title " started")
	}
	
	Stop() {
		this.logEvent(1, "Stopping" )
		this.ih.KeyOpt("{All}", "-N-S")  ; Undo end and Suppress
		this.ih.Stop()
		this.engine.keyboard.Token := ""
		this.logEvent(1, "Stopped" )
	}	
	
	ReceiveKeyDown(InputHook, VK, SC) {
		local key
		; ToolTip, % "VK: " VK ", SC: " SC
		; First, translate some numpad keys to their actual equivalents.
		if (SC = 284) {
            ; (The VK does not distinguish between Enter and NumpadEnter)
			key := "NumpadEnter"
		} else if (SC = 331) {
            ; The aux keyboard will pirate the arrow keys, because they are sent as Numpad keys. Convert them to main keyboard keys 
			key := "Left"
		} else if (SC = 336) {
			key := "Down"
		} else if (SC = 333) {
			key := "Right"
		} else if (SC = 328) {
			key := "Up"
		} else if (SC = 339) {
			key := "Del"
		} else if (SC = 335) {
			key := "End"
		} else if (SC = 337) {
			key := "PgDn"
		} else if (SC = 327) {
			key := "Home"
		} else if (SC = 329) {
			key := "PgUp"
		} else {
            key := GetKeyName(Format("vk{:x}", VK)) 
		}
		this.logEvent(5, "Receiving keydown on " VK " and " SC " translated to " key)
		
		; Next handle a ton of different inbound keys uniquely
		; In each case:
		; key will be whatever we want to say was pressed. It's changed in some cases
		; sendkey will be what we want to push to the screen right now
		; we should call a single handler function with key
			; add will append this key to the pending token
			; end will notify other code this token is ready to evaluate
			; cancel will clear the token with no expansion
		Switch key
		{
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				; Basic letters split up because AHK can only see the first 20
				this.AddKeyToToken(key)
				sendkey := key
			case "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
				; Basic letters split up because AHK can only see the first 20
				this.AddKeyToToken(key)
				sendkey := key
			case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				; Number keys can either be shifted or unshifted
				sendkey := key
				if (GetKeyState("Shift", "P")) {
					if (key == "0") {
						key := "10"
					}
                    shiftedKey := this.engine.keyboard.ShiftedNumerals[key]
					if (InStr("@&", shiftedKey)) {
						this.CancelToken(shiftedKey)
					} else {
						sendKey := ""
						this.EndToken("{" shiftedKey "}")
					}
				} else {
					this.AddKeyToToken(key)
				}
			case ".", ",", "'", """", "[", "]", "/", ";", "[", "]", "\", "-", "=", "``": 
				; These are punctuation keys that can be combined with ctrl to cancel a token, or sent plain to end a token
				sendkey := ""
				if (not GetKeyState("Control", "P")) {
					this.EndToken(key)
				} else {
					this.CancelToken("{Ctrl-" key "}")
					Send, % key
				}
			case "Space", "Enter", "Tab", "Insert":
				; These are like punctation, but must be sent in curly braces
				sendkey := ""
				if (not GetKeyState("Control", "P")) {
					this.EndToken("{" key "}")
				} else {
					this.CancelToken("{Ctrl-" key "}")
					Send, % "{" key "}"
				}
			case "Home", "End", "PgUp", "PgDn", "Left", "Up", "Right", "Down", "Delete":
				; Navigation always cancels the token
				sendKey := "{" key "}"
				this.CancelToken(sendkey)
			case "Backspace":
				; Backspace is its own thing. We have to manage the token and even pull old tokens back from cache
				sendKey := "{" key "}"
				this.RemoveKeyFromToken()
			case "LShift", "RShift", "LControl", "RControl", "LAlt", "RAlt", "LWin", "RWin", "CapsLock":
				; Handle these just by sending nothing
				sendKey := ""
				this.IgnoreKey(key)
			case "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0":
				mappedKey := this.aux.RemapKey(key)
				sendkey := mappedKey
				this.AddKeyToToken(sendkey)
			case "Numlock", "NumpadDot", "NumpadDiv", "NumpadMult", "NumpadSub", "NumpadAdd", "NumpadEnter":
				mappedKey := this.aux.RemapKey(key)
				sendkey := mappedKey
				this.AddKeyToToken(sendkey)
			case "NumpadHome", "NumpadUp", "NumpadPgUp", "NumpadRight", "NumpadPgDn", "NumpadDown", "NumpadEnd", "NumpadLeft", "NumpadClear", "NumpadIns", "NumpadDel":
				mappedKey := this.aux.RemapKey(key)
				sendkey := mappedKey
				this.AddKeyToToken(sendkey)
			default:
				sendKey := "{" key "}"
		} 
		; Send, % sendKey
		if (sendKey != ""){
			this.logEvent(3, "Passthrough: {Blind}" sendKey)
			SendInput, % "{Blind}" sendKey
			;Msgbox, % "Sent {Blind}" sendKey
		}
		; sendKey is blanked out, so be sure to check on the original key 
		if ((this.engine.keyboard.AutoPunctuationSent) and (Instr(this.engine.keyboard.EndKeys_hard, key))) {
			this.logEvent(4, "Adding trailing autospace back after deletion with " sendKey)
			Send, {Space}
		}
		this.engine.keyboard.AutoPunctuationSent := false
	}

	ReceiveKeyUp(InputHook, VK, SC) {
		local key
		if (not SC = 284) {
			key := GetKeyName(Format("vk{:x}", VK)) ; (The VK does not distinguish between Enter and NumpadEnter)
		} else {
			key := "NumpadEnter"
		}
		Switch key
		{
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				this.LeaveChord(key)
			case "n", "o", "p", "r", "q", "s", "t", "u", "v", "w", "x", "y", "z": 
				this.LeaveChord(key)
			case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
				this.LeaveChord(key)
			case "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0":
				this.aux.LeaveChord(key)
			case "Numlock", "NumpadDot", "NumpadDiv", "NumpadMult", "NumpadSub", "NumpadAdd", "NumpadEnter":
				this.aux.LeaveChord(key)
			case "NumpadHome", "NumpadUp", "NumpadPgUp", "NumpadRight", "NumpadPgDn", "NumpadDown", "NumpadEnd", "NumpadLeft", "NumpadClear", "NumpadIns", "NumpadDel":
				this.aux.LeaveChord(key)
		}
	}
	
	IgnoreKey(key) {
		this.logEvent(4, "Ignoring key: " key)
	}
	AddKeyToToken(key) {
		this.logEvent(4, "Adding key to token: " key)
		this.accumulator.AddKeyToToken(key)
	}
	RemoveKeyFromToken() {
		this.logEvent(4, "Removing key from token")
		this.accumulator.RemoveKeyFromToken(key)
	}
	EndToken(key) {
		this.logEvent(4, "Ending token: " key)
		this.accumulator.EndToken(key)
		Send, % "{Blind}" key
	}
	CancelToken(key) {
		this.logEvent(4, "Cancelling token: " key)
		this.accumulator.CancelToken(key)
	}



	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent(this.name,A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}