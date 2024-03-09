﻿
Class SerialExpander {

	__New(engine) {
		this.title := "SerialExpander"
		this.name := "serialexpander"
		this.engine := engine
		this.logQueue := engine.logQueue
		this.logVerbosity := this.engine.LogVerbosity

		this.nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

		this.logEvent(3, "Engine " this.title " instantiated")
	}

	Expand(token) {
		this.logEvent(2, "Before expansion map.qwerds count = " this.engine.map.qwerds.count)
		this.logEvent(2, "Expanding after " token.ender " with " token.input)

		lastToken := 0
		nextToLastToken := 0
		lastToken := this.engine.record[this.engine.record.MaxIndex()]
		nextToLastToken := this.engine.record[this.engine.record.MaxIndex() - 1]

        this.logEvent(4, "Double depth data are lastToken ender " lastToken.ender ", lastToken input " lastToken.input ", nextToLastToken ender " nextToLastToken.ender)

		if (lastToken.ender == ";") {
			this.logEvent(2, "; could be glue: input=" token.input ", horizon=" this.engine.Accumulator.retrievedTokenHorizon ", lastinput=" lastToken.input ", horizon<maxindex=" this.engine.Accumulator.retrievedTokenHorizon "<" this.engine.record.MaxIndex())
		}

        ; hard coded use semicolon to glue two words together
		if ((token.input) and (this.engine.Accumulator.retrievedTokenHorizon <= this.engine.record.MaxIndex()) and (lastToken) and (lastToken.input) and (lastToken.ender == ";")) {
            ; Any normal use of ; will have token ending with ;, then a space. If the previous token has a semicolon, then glue it
			this.logEvent(2, "Handling " lastToken.ender token.input " as a glued word")
            token.extra_backspaces := 1
		}

        ; hard coded contraction handling
		if ((lastToken) and (lastToken.ender == "'") and (InStr("|s|d|m|re|r|v|l|ll|t|", token.input))) {
			this.logEvent(4, "Handling " lastToken.ender token.input " as a contraction")
			Switch token.input
			{
				Case "s":
					this.nullQwerd.word := "s"
					this.nullQwerd.qwerd := " s"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "d":
					this.nullQwerd.word := "d"
					this.nullQwerd.qwerd := "d"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "m":
					this.nullQwerd.word := "m"
					this.nullQwerd.qwerd := "m"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "re":
					this.nullQwerd.word := "re"
					this.nullQwerd.qwerd := "re"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "r":
					this.nullQwerd.word := "re"
					this.nullQwerd.qwerd := "r"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "v":
					this.nullQwerd.word := "ve"
					this.nullQwerd.qwerd := "v"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "ll":
					this.nullQwerd.word := "ll"
					this.nullQwerd.qwerd := "ll"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "l":
					this.nullQwerd.word := "ll"
					this.nullQwerd.qwerd := "l"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Case "t":
					this.nullQwerd.word := "t"
					this.nullQwerd.qwerd := "t"
					token.qwerdobject := this.nullQwerd
					token.output := this.nullQwerd.word
					token.match := 1
				Default:
					this.logEvent(1, "Cannot reach this line handling " lastToken.ender token.input " as contraction")
			}
        ; hard coded command line switch handling (things like 'command -sw ' don't expand)
		} else if ((lastToken) and (nextToLastToken) and (lastToken.ender == "-") and (lastToken.input == "") and (nextToLastToken.ender == "{Space}")) {
			this.logEvent(4, "Handling " lastToken.ender token.input " as a command line switch")
			this.nullQwerd.word := token.input
            this.nullQwerd.qwerd := token.input
            token.qwerdobject := this.nullQwerd
            token.output := this.nullQwerd.word
            token.match := 1
        ; Testing for qwerds.item(key).word creates a blank object with that key, if one does not exist. 
        ; In this case, that was creating blank qwerd keys of my passwords - not good. 
        ; I need to find other cases, because the number of qwerd keys increases all day long - not good 
        ; This fixes creation of my passwords as keys, so it's a keeper of a fix
        } else if (this.engine.map.qwerds.exists(token.input)) {
            if (this.engine.map.qwerds.item(token.input).word) {
                token.qwerdobject := this.engine.map.qwerds.item(token.input)
                token.output := token.qwerdobject.word
                token.match := 1
            } else {
                this.logEvent(1, "Found a token that exists and has no word, " token.input)
            }
		} else {
			this.nullQwerd.word := token.input
			this.nullQwerd.qwerd := token.input
			token.qwerdobject := this.nullQwerd
			token.miss := 1
		}
		this.logEvent(2, token.input " -> " token.output)
		this.logEvent(2, "After expansion map.qwerds count = " this.engine.map.qwerds.count)
		return token
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