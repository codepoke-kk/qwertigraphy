
class AuxKeyboardEngine
{
	logQueue := new Queue("AuxEngineQueue")
	logVerbosity := 4
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
			mapfields := StrSplit(A_LoopReadLine, ",")
			keyfields := StrSplit(mapfields[1], ";")
			this.keymap[mapfields[1]] := mapfields[2]
			this.logEvent(4, "Setting " mapfields[1] " to " mapfields[2])
			this.keymapCount += 1
			if (keyfields.MaxIndex() = 1) {
				this.keymap[keyfields[1]] := mapfields[2]
			} else if (keyfields.MaxIndex() = 2) {
				this.keymap[keyfields[1] . keyfields[2]] := mapfields[2]
				this.keymap[keyfields[2] . keyfields[1]] := mapfields[2]
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
	}
	
	RemapKey(key) {
		if (this.keymap[key] and this.enabled) {
			this.logEvent(4, "Matched valid keymap for " key)
			rekey := ""
			this.chord .= "" . key
		} else {
			this.logEvent(4, "No valid keymap for " key)
			rekey := RegExReplace(key, "Numpad")
		}
		this.logEvent(2, "Remapping " key " to " rekey " and chord is " this.chord)
		Return rekey
	}
	LeaveChord(key) {
		this.logEvent(4, "Testing leaving chord with " key " against " this.chord)
		chordLength := StrLen(this.chord)
		if (this.enabled and chordLength) {
			if (this.keymap[this.chord]) {
				this.logEvent(3, "Matched chord " this.chord " as " this.keymap[this.chord])
				; Send to screen 
				Send, % this.keymap[this.chord]
				; Send to token
				this.engine.keyboard.Token .= this.keymap[this.chord]
			}
		}
		; Clear the chord buffer for a fresh start 
		this.Flush()
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
