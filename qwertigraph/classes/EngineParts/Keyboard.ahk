
Class Keyboard {

	__New(engine) {
		this.title := "Keyboard"
		this.name := "keyboard"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
		
		this.EndKeys_hard := " .,?!;:'""-_{{}{}}[]/\+=|()@#$%^&*<>"
		this.Letters := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		this.Numerals := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
		this.ShiftedNumerals := ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
		this.Token := ""
		this.TokenEndKey := ""
		this.TokenStartTicks := A_TickCount
		this.ChordPressStartTicks := 0
		this.ScriptCalled := false
		this.AutoSpaceSent := false 
		this.ChordMinimumLength := 2
		this.ChordReleaseWindow := 150
		this.ChordReleaseWindows := []
		this.CoachAheadLines := 100
		this.CoachAheadTipDuration := 5000
		this.CoachAheadWait := 1000
		
		; I need to allow longer for a chord release. So, a 2-key chord gets 100ms, but a 4-key chord gets 200ms from first press to first release 
        increment := Round(this.ChordReleaseWindow / 3)
        Loop, 26 {
            this.ChordReleaseWindows[A_Index] := increment + (A_Index * increment)
        }
		
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