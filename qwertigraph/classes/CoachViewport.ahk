
Global RegexCoachSavings
Global RegexCoachWord
Global RegexCoachQwerd
Global RegexCoachForm
Global RegexCoachSaves
Global RegexCoachPower
Global RegexCoachMatch
Global RegexCoachMiss
Global RegexCoachOther
Global CoachEventsLV

; Predefine a coach object. The Trainer will redefine it. 
coach := {}

Gui, Tab, Coach


;; Add regex search fields
;Gui, Add, Edit, -WantReturn x12  y64 w90 h20 vRegexWhere,  
;Gui, Add, Edit, -WantReturn x102 y64 w100  h20 vRegexWhen,  
;Gui, Add, Edit, -WantReturn x202 y64 w576  h20 vRegexWhat, 
;Gui, Add, Edit, -WantReturn x778 y64 w60  h20 vRegexHow,
;Gui, Add, Button, Default x838 y64 w90 h20 gSearchLogEvents, Search
;
;; Add the data ListView
;Gui, Add, ListView, x12 y84 w916 h420 vLogEventsLV, Where|When|What|How
;LV_ModifyCol(4, "Integer")  ; For sorting, indicate that the Usage column is an integer.
;LV_ModifyCol(1, 90)
;LV_ModifyCol(2, 100)
;LV_ModifyCol(3, 576)
;LV_ModifyCol(4, 30)

; Add regex search fields
Gui, Add, Edit, -WantReturn x12  y64 w50 h20 vRegexCoachSavings, 
Gui, Add, Edit, -WantReturn x62  y64 w180 h20 vRegexCoachWord,  
Gui, Add, Edit, -WantReturn x242 y64 w80 h20 vRegexCoachQwerd,  
Gui, Add, Edit, -WantReturn x322 y64 w80 h20 vRegexCoachChord,   
Gui, Add, Edit, -WantReturn x402 y64 w60 h20 vRegexCoachChordable,  
Gui, Add, Edit, -WantReturn x462 y64 w80 h20 vRegexCoachForm, 
Gui, Add, Edit, -WantReturn x542 y64 w50 h20 vRegexCoachPower, 
Gui, Add, Edit, -WantReturn x592 y64 w50 h20 vRegexCoachSaves, 
Gui, Add, Edit, -WantReturn x642 y64 w50 h20 vRegexCoachMatch, 
Gui, Add, Edit, -WantReturn x692 y64 w50 h20 vRegexCoachCMatch, 
Gui, Add, Edit, -WantReturn x742 y64 w50 h20 vRegexCoachMiss, 
Gui, Add, Edit, -WantReturn x792 y64 w50 h20 vRegexCoachOther, 
Gui, Add, Button, x838 y64 w90 h20 gCoachFilterCoachEvents, Filter

; Add the data ListView
Gui, Add, ListView, x12 y84 w916 h476 vCoachEventsLV, Savings|Word|Qwerd|Chord|Chordable|Form|Power|Saves|Matches|Chords|Misses|Other
LV_ModifyCol(1, "Integer")  ; For sorting, indicate columns are integer.
LV_ModifyCol(7, "Float")  
LV_ModifyCol(8, "Integer")  
LV_ModifyCol(9, "Integer")  
LV_ModifyCol(10, "Integer")  
LV_ModifyCol(11, "Integer")  
LV_ModifyCol(1, 50)
LV_ModifyCol(2, 180)
LV_ModifyCol(3, 80)
LV_ModifyCol(4, 80)
LV_ModifyCol(5, 60)
LV_ModifyCol(6, 80)
LV_ModifyCol(7, 50)
LV_ModifyCol(8, 50)
LV_ModifyCol(9, 50)
LV_ModifyCol(10, 50)
LV_ModifyCol(11, 50)
LV_ModifyCol(12, 50)

CoachFilterCoachEvents() {
	global coach
	coach.filterCoachEvents()
}

class CoachViewport
{
	map := ""
	speedViewer := ""
	coachQueues := []
	interval := 1000
	phrasePowerThreshold := 100
	tip_power_threshold := 1
	coachEvents := ComObjCreate("Scripting.Dictionary")
	phrases := ComObjCreate("Scripting.Dictionary")
	phrase_buffer := ""
	qwerds_buffer := ""
	logQueue := new Queue("CoachQueue")
	logVerbosity := 2
	
	__New(map, speedViewer)
	{
		this.map := map
		this.logVerbosity := this.map.qenv.properties.LoggingLevelCoach
		this.phrasePowerThreshold := this.map.qenv.properties.PhraseEnthusiasm
		this.speedViewer := speedViewer
		
        this.timer := ObjBindMethod(this, "DequeueEvents")
        timer := this.timer
        SetTimer % timer, % this.interval
		this.LogEvent(2, "Coach initialized")
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hSearchCoachEvents)
			this.filterCoachEvents()
	}
	
	filterCoachEvents() {
		local garbage
		GuiControlGet RegexCoachSavings
		GuiControlGet RegexCoachWord
		GuiControlGet RegexCoachQwerd
		GuiControlGet RegexCoachChord
		GuiControlGet RegexCoachChordable
		GuiControlGet RegexCoachForm
		GuiControlGet RegexCoachPower
		GuiControlGet RegexCoachSaves
		GuiControlGet RegexCoachMatch
		GuiControlGet RegexCoachCMatch
		GuiControlGet RegexCoachMiss
		GuiControlGet RegexCoachOther
		
		;global SaveProgress
		
		
		this.logEvent(3, "RegexCoachSavings " RegexCoachSavings ", RegexCoachWord " RegexCoachWord ", RegexCoachQwerd " RegexCoachQwerd ", RegexCoachChord " RegexCoachChord ", RegexCoachChordable " RegexCoachChordable ", RegexCoachForm " RegexCoachForm ", RegexCoachPower " RegexCoachPower ", RegexCoachSaves " RegexCoachSaves ", RegexCoachMatch " RegexCoachMatch ", RegexCoachCMatch " RegexCoachCMatch ", RegexCoachMiss " RegexCoachMiss ", RegexCoachOther " RegexCoachOther)
		
		requiredMatchCount := 0
		requiredMatchCount += (RegexCoachSavings) ? 1 : 0
		requiredMatchCount += (RegexCoachWord) ? 1 : 0
		requiredMatchCount += (RegexCoachQwerd) ? 1 : 0
		requiredMatchCount += (RegexCoachChord) ? 1 : 0
		requiredMatchCount += (RegexCoachChordable) ? 1 : 0
		requiredMatchCount += (RegexCoachForm) ? 1 : 0
		requiredMatchCount += (RegexCoachPower) ? 1 : 0
		requiredMatchCount += (RegexCoachSaves) ? 1 : 0
		requiredMatchCount += (RegexCoachMatch) ? 1 : 0
		requiredMatchCount += (RegexCoachCMatch) ? 1 : 0
		requiredMatchCount += (RegexCoachMiss) ? 1 : 0
		requiredMatchCount += (RegexCoachOther) ? 1 : 0
		
		Gui, ListView, CoachEventsLV
		LV_Delete()
		
		for wordKey, garbage in this.coachEvents {
			word := this.coachEvents.item(wordKey)
			foundKey := 0
			foundKey += this.testField("RegexCoachSavings", wordKey, word.savings, RegexCoachSavings)
			foundKey += this.testField("RegexCoachWord", wordKey, word.word, RegexCoachWord)
			foundKey += this.testField("RegexCoachQwerd", wordKey, word.qwerd, RegexCoachQwerd)
			foundKey += this.testField("RegexCoachChord", wordKey, word.chord, RegexCoachChord)
			foundKey += this.testField("RegexCoachChordable", wordKey, word.chordable, RegexCoachChordable)
			foundKey += this.testField("RegexCoachForm", wordKey, word.form, RegexCoachForm)
			foundKey += this.testField("RegexCoachPower", wordKey, word.power, RegexCoachPower)
			foundKey += this.testField("RegexCoachSaves", wordKey, word.saves, RegexCoachSaves)
			foundKey += this.testField("RegexCoachMatch", wordKey, word.match, RegexCoachMatch)
			foundKey += this.testField("RegexCoachCMatch", wordKey, word.cmatch, RegexCoachCMatch)
			foundKey += this.testField("RegexCoachMiss", wordKey, word.miss, RegexCoachMiss)
			foundKey += this.testField("RegexCoachOther", wordKey, word.other, RegexCoachOther)
			;if (RegexCoachSavings) {
			;	if (RegExMatch(word.savings,RegexCoachSavings)) {
			;		this.logEvent(4, "RegexCoachSavings matched " wordKey)
			;		foundKeys[wordKey] := (foundKeys[wordKey]) ? foundKeys[wordKey] + 1 : 1
			;	}
			;}
		
			if (foundKey >= requiredMatchCount) {
				LV_Add(, word.savings, word.word, word.qwerd, word.chord, word.chordable, word.form, word.power, word.saves, word.match, word.cmatch, word.miss, word.other)
			}
		}
	}
	
	testField(fieldName,wordKey,haystack,needle) {
		this.logEvent(4, "Testing " fieldName " for " wordKey " against " haystack " looking for " needle)
		if (needle) {
			if (RegExMatch(haystack,"i)" needle)) {
				this.logEvent(4, fieldName " matched " wordKey)
				return 1
			}
		}
		return 0
	}
	
	addQueue(coachQueue) { 
		this.coachQueues.Push(coachQueue)
	}
	
	DequeueEvents() {
        local index
		For index, coachQueue in this.coachQueues {
			Loop, % coachQueue.getSize() {
				coachEvent := coachQueue.dequeue()
				if (not coachEvent.word) {
					; Ignore null words
					Continue
				}
				if (coachEvent.miss or coachEvent.other) {
					coachEvent.saves *= -1
				}
				this.coachItem(coachEvent)
				this.coachPhrasing(coachEvent)
				this.coachChording(coachEvent)
			}
		}
	}
	
	coachItem(coachEvent) {
		eventKey := coachEvent.word
		StringLower, eventKey, eventKey
		coachEvent.word := eventKey
		if (not this.coachEvents.item(eventKey)) {
			this.coachEvents.item(eventKey) := coachEvent
		} else {
			this.coachEvents.item(eventKey).match += coachEvent.match
			this.coachEvents.item(eventKey).cmatch += coachEvent.cmatch
			this.coachEvents.item(eventKey).miss += coachEvent.miss
			this.coachEvents.item(eventKey).other += coachEvent.other
		}
		this.coachEvents.item(eventKey).savings += coachEvent.saves
	}
	
	coachChording(coachEvent) {
		if ((not coachEvent.chorded) and (coachEvent.chordable = "active")) {
			this.LogEvent(2, "Chord coaching '" coachEvent.word "' against '" coachEvent.chord "'")
			this.flashTip_chord(coachEvent)
		} else {
			this.LogEvent(2, "Not chord coaching '" coachEvent.word "' against '" coachEvent.chord "' because " coachEvent.chorded " or " coachEvent.chordable)
		}
	}
	
	coachPhrasing(coachEvent) {
		this.phrase_buffer .= " " coachEvent.word
		this.qwerds_buffer .= " " coachEvent.qwerd
		this.LogEvent(4, "Phrase coaching '" coachEvent.word "' against '" this.phrase_buffer "'")
		words := StrSplit(this.phrase_buffer, " ")
		; We're going to grow current_phrase out to a max, and check each version for presence in hints
		; Then we're going to count the number of times we used each phrase and mark it for possible creation 
		current_phrase := Trim(words[words.MaxIndex()])
		Loop, % words.MaxIndex() {
			word_index := words.MaxIndex() - A_Index
			current_phrase := words[word_index] " " current_phrase
			this.LogEvent(4, "Testing " current_phrase)
			if (this.phrases.item(current_phrase)) {
				this.phrases.item(current_phrase) += 1
			} else {
				this.phrases.item(current_phrase) := 1
			}
			; Now, if the count of this phrase's use exceeds 10, let's log that in coaching
			; A 10-character phrase must be seen 3 times in 10000 characters 
			if ((word_index > 1) and (this.phrases.item(current_phrase) > 2)) {
				this.LogEvent(1, "Testing '" current_phrase "' at " (StrLen(current_phrase) * this.phrases.item(current_phrase) * this.phrasePowerThreshold) " > " this.speedViewer.out_chars)
				if ((StrLen(current_phrase) * this.phrases.item(current_phrase) * this.phrasePowerThreshold) > this.speedViewer.out_chars) {
					if (not this.map.hints.item(current_phrase).word) {
						coaching := new CoachingEvent()
						coaching.word := current_phrase
						coaching.qwerd := "_create_"
						coaching.form := "h"
						coaching.power := 3
						coaching.endKey := " "
						coaching.miss := true
						coaching.saves := Round(StrLen(current_phrase) * -.667)
						this.coachItem(coaching)
						this.LogEvent(1, "Coaching new potential phrase '" current_phrase "' at " (StrLen(current_phrase) * this.phrases.item(current_phrase) * this.phrasePowerThreshold) " > " this.speedViewer.out_chars)
						this.phrases.item(current_phrase) := 1
					} else {
						this.LogEvent(1, "Not adding new potential phrase '" current_phrase "' - redundant")
						this.phrases.item(current_phrase) := 1
					}
				} else {
					if (this.phrases.item(current_phrase) > 10) {
						this.LogEvent(1, "Skipping new potential phrase '" current_phrase "' at " (StrLen(current_phrase) * this.phrases.item(current_phrase) * this.phrasePowerThreshold) " > " this.speedViewer.out_chars)
					}
				}
			}
			if (this.map.hints.item(current_phrase)) {
				coaching := new CoachingEvent()
				coaching.word := current_phrase
				coaching.qwerd := this.map.hints.item(current_phrase).qwerd
				coaching.form := this.map.hints.item(current_phrase).form
				coaching.power := this.map.hints.item(current_phrase).power
				coaching.endKey := coachEvent.endKey
				if (not InStr(this.qwerds_buffer, this.map.hints.item(current_phrase).qwerd)) {
					coaching.miss := true
					coaching.saves := -1 * this.map.hints.item(current_phrase).saves
				} else {
					coaching.match := true
					coaching.saves := this.map.hints.item(current_phrase).saves
				}	
				this.coachItem(coaching)
				this.flashTip(coaching)
			}
		}
		if (coachEvent.endKey != " ") {
			this.phrase_buffer := ""
			this.qwerds_buffer := ""
		}
	}
	
	flashTip(coachEvent) {
		if (coachEvent.power < this.tip_power_threshold) {
			return
		}
		CoordMode, ToolTip, Relative
		;MsgBox, % "flashing " coachEvent.qwerd " as " this.map.qwerds.item(coachEvent.qwerd).dictionary " and got " unreliable
		if (coachEvent.chordable = "active") {
			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd " (" coachEvent.chord ")", 0, 0 ; A_CaretX, A_CaretY + 30
		} else {
			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd, 0, 0 ;, A_CaretX, A_CaretY + 30
		}
		SetTimer, ClearToolTipCoaching, -5000
		return 

		ClearToolTipCoaching:
		  ToolTip
		return 
	}
	
	flashTip_chord(coachEvent) {
		CoordMode, ToolTip, Relative
		;MsgBox, % "flashing chord " coachEvent.qwerd " as " this.map.qwerds.item(coachEvent.qwerd).dictionary " and got " unreliable
		if (coachEvent.chordable = "active") {
			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= ** " coachEvent.qwerd " (" coachEvent.chord ") **", 0, 0 ; A_CaretX, A_CaretY + 30
		} 
		SetTimer, ClearToolTipCoaching_chord, % (-1 * this.map.qenv.properties.CoachAheadTipDuration)
		return 

		ClearToolTipCoaching_chord:
		  ToolTip
		return 
	}

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("coach",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
