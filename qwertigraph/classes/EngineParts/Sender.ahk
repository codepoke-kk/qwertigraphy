
Class Sender {

	__New(engine) {
		this.title := "Sender"
		this.name := "sender"
		this.engine := engine 
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity
		
		this.logEvent(3, "Engine " this.title " instantiated")
	}
	
	Send(token) {
		this.logEvent(4, "Sending " token.input " as " token.output)
		
		if ((this.engine.keyboard.AutoSpaceSent) and (not token.input)) {
			; We sent a space after sending a chord and this is a bare end key. We need to delete that autospace
			this.logEvent(4, "Deleting autospace and setting autopunctuation")
			Send, {Backspace} 
			this.engine.keyboard.AutoPunctuationSent := true
		}
		this.engine.keyboard.AutoSpaceSent := false
		
		if (not StrLen(token.output)) {
			this.logEvent(4, "Token input " token.input " unmatched")
			token.active_edited := false 
			Send, % "{Blind}" token.ender
			return token
		} else if (token.input == token.output) {
			this.logEvent(4, "Token input " token.input " matched output")
			token.active_edited := false 
			Send, % "{Blind}" token.ender
			return token
		} else if (Instr(token.output, ")", , 0)) {
			this.logEvent(4, "Token output " token.output " is a script call with end character " token.ender)
			token.deleted_characters := StrLen(token.input)
			this.logEvent(4, "Sending " token.deleted_characters " backspaces")
			Send, % "{Blind}" "{Backspace " token.deleted_characters "}"
			function_name := Substr(token.output, 1, Instr(token.output, "(") - 1)
			this.logEvent(4, "Function name is " function_name)
			fn := Func(function_name)
			this.logEvent(4, "Function is " fn.Name)
			fn.Call(token.input, token.output, token.ender)
			if (token.ender) {
				this.logEvent(4, "Sending " token.ender)
				Send, % "{Blind}" token.ender
			}
			this.logEvent(4, "Call complete")
			return token
		} else {
			token.active_edited := true 
			token.deleted_characters := StrLen(token.input)
			this.logEvent(4, "Sending " token.deleted_characters " backspaces")
			Send, % "{Blind}" "{Backspace " token.deleted_characters "}"
			this.logEvent(4, "Sending " token.output)
			Send, % token.output
			this.logEvent(4, "Sending " token.ender)
			Send, % "{Blind}" token.ender
			return token
		}
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