
Class Listener {

	__New(engine) {
		this.title := "Listener"
		this.name := "listener"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4 ; this.engine.LogVerbosity
		
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
		this.ih.KeyOpt("{RAlt}", "V") 
		this.ih.KeyOpt("{LWin}", "V") 
		this.ih.KeyOpt("{RWin}", "V") 
		this.ih.OnKeyDown := ObjBindMethod(this, "ReceiveKeyDown")
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
		Critical 
		Switch key
		{
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				; Basic letters split up because AHK can only see the first 20
				this.AddKeyToToken(key)
				SendInput, % "{Blind}" key
			case "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
				; Basic letters split up because AHK can only see the first 20
				this.AddKeyToToken(key)
				SendInput, % "{Blind}" key
			case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				; Number keys can either be shifted or unshifted
				if (GetKeyState("Shift", "P")) {
					if (key == "0") {
				 		key := "10"
					}
					shiftedKey := this.engine.keyboard.ShiftedNumerals[key]
					this.EndToken("{" shiftedKey "}")
				} else {
					this.AddKeyToToken(key)
					SendInput, % "{Blind}" key
				 }
			case ".", ",", "'", """", "[", "]", "/", ";", "[", "]", "\", "-", "=", "``": 
				; These are punctuation keys that can be combined with ctrl to cancel a token, or sent plain to end a token
				this.EndToken(key)
			case "Space", "Enter", "Tab", "Insert":
				; These are like punctation, but must be sent in curly braces
				this.EndToken("{" key "}")
			case "Home", "End", "PgUp", "PgDn", "Left", "Up", "Right", "Down", "Delete", "Del":
				; Navigation always cancels the token
				this.CancelToken("{" key "}")
				modifierString := this.getModifierString()
				SendInput, % modifierString "{" key "}"
			case "Backspace":
				; Backspace is its own thing. We have to manage the token and even pull old tokens back from cache
				this.logEvent(4, "About to backspace")
				this.RemoveKeyFromToken()
				this.logEvent(4, "Removed from token")
				modifierString := this.getModifierString()
				SendInput, % modifierString "{" key "}"
				this.logEvent(4, "Sent backspace")
			case "LShift", "RShift", "LControl", "RControl", "LAlt", "RAlt", "LWin", "RWin", "CapsLock":
				; Handle these just by sending nothing
				this.IgnoreKey(key)
			case "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0":
				mappedKey := this.engine.aux.RemapKey(key)
				this.logEvent(4, "Aux keyboard adding to token: " key "->" mappedKey)
				this.AddKeyToToken(mappedKey)
			case "NumpadHome", "NumpadUp", "NumpadPgUp", "NumpadRight", "NumpadPgDn", "NumpadDown", "NumpadEnd", "NumpadLeft", "NumpadClear", "NumpadIns", "NumpadDel":
				mappedKey := this.engine.aux.RemapKey(key)
				this.logEvent(4, "Aux keyboard ending token: " key "->" mappedKey)
				this.EndToken(mappedKey)
			case "Numlock", "NumpadDot", "NumpadDiv", "NumpadMult", "NumpadSub", "NumpadAdd", "NumpadEnter":
				mappedKey := this.engine.aux.RemapKey(key)
				this.logEvent(4, "Aux keyboard adding to token: " key "->" mappedKey)
				this.AddKeyToToken(mappedKey)
                ;SendInput, % "{Blind} " mappedKey
			default:
				this.logEvent(4, "Defaulting unrecognized input as: {" key "}")
				SendInput, % "{" key "}"
		} 
		Critical Off 
	}

	ReceiveKeyUp(InputHook, VK, SC) {
		local key
		if (not SC = 284) {
			key := GetKeyName(Format("vk{:x}", VK)) ; (The VK does not distinguish between Enter and NumpadEnter)
		} else {
			key := "NumpadEnter"
		}
		Critical 
		Switch key
		{
			case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
				this.engine.chordexpander.LeaveChord(key)
			case "n", "o", "p", "r", "q", "s", "t", "u", "v", "w", "x", "y", "z": 
				this.engine.chordexpander.LeaveChord(key)
			case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
				this.engine.chordexpander.LeaveChord(key)
			case "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0":
				this.engine.aux.LeaveChord(key)
			case "Numlock", "NumpadDot", "NumpadDiv", "NumpadMult", "NumpadSub", "NumpadAdd", "NumpadEnter":
				this.engine.aux.LeaveChord(key)
			case "NumpadHome", "NumpadUp", "NumpadPgUp", "NumpadRight", "NumpadPgDn", "NumpadDown", "NumpadEnd", "NumpadLeft", "NumpadClear", "NumpadIns", "NumpadDel":
				this.engine.aux.LeaveChord(key)
		}
		Critical Off
	}
	
	IgnoreKey(key) {
		this.logEvent(4, "Ignoring key: " key)
	}
	AddKeyToToken(key) {
		this.logEvent(4, "Adding key to token: " key)
		if (GetKeyState("Control", "P")) {
			this.CancelToken("{" key "}")
		} else {
			if ((not this.engine.keyboard.Token) and (not this.engine.keyboard.ChordPressStartTicks)) {
				
				this.logEvent(4, "First key added to token, so opens possible chord")
				this.engine.keyboard.ChordPressStartTicks := A_TickCount
			}
			this.accumulator.AddKeyToToken(key)
		}
	}
	RemoveKeyFromToken() {
		this.logEvent(4, "Removing key from token")
		this.accumulator.RemoveKeyFromToken(key)
		this.logEvent(4, "Backspace kills chord")
		this.engine.keyboard.ChordPressStartTicks := 0
	}
	EndToken(key) {
		this.logEvent(4, "Ending token: " key)
        ; If this end key is not wrapped in braces and the control key is down, then don't expand 
		if ((Substr(key, 1, 1) != "{") and (GetKeyState("Control", "P"))) {
            ; Ctrl-., Ctrl-,, etc. should go ahead and give me the punctuation but not expand the word 
			this.CancelToken(key)
			if (InStr("{Space},.'""", key)) {
				this.logEvent(4, "Passing token through after cancelling, due to ctrl key: " key)
				Send, % key
			}
		} else {
            ; I need Ctrl-Home and Ctrl-End to actually work, so let those go through as typed
			this.accumulator.EndToken(key)
			this.logEvent(4, "Serial token kills chord")
			this.engine.keyboard.ChordPressStartTicks := 0
		}
	}
	CancelToken(key) {
		this.logEvent(4, "Cancelling token: " key)
		this.accumulator.CancelToken(key)
		this.logEvent(4, "Cancel token kills chord")
		this.engine.keyboard.ChordPressStartTicks := 0
	}


	getModifierString()	{
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

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent(this.name,A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}