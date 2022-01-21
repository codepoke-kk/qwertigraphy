
Class Keyboard {

	__New(engine) {
		this.title := "Keyboard"
		this.name := "keyboard"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := 4
		
		this.EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
		this.Letters := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		this.Numerals := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
		this.ShiftedNumerals := ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
		this.Token := ""
		this.TokenEndKey := ""
		this.TokenStartTicks := A_TickCount
		this.CapsLock := false
		this.ChordLength := 0
		this.MaxChordLength := 0
		this.ChordPressStartTicks := 0
		this.ChordReleaseStartTicks := 0
		this.ScriptCalled := false
		this.AutoSpaceSent := true
		this.AutoPunctuationSent := false
		this.ChordReleaseWindow := 150
		this.ChordReleaseWindows := []
		this.CoachAheadLines := 100
		this.CoachAheadTipDuration := 5000
		this.CoachAheadWait := 1000
		
		this.logEvent(3, "Engine " this.title " instantiated")
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