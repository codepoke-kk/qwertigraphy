; This is awkward, but I'm going to do 2 tabs with this one class

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

Global RegexHistoricalSavings
Global RegexHistoricalWord
Global RegexHistoricalQwerd
Global RegexHistoricalForm
Global RegexHistoricalSaves
Global RegexHistoricalPower
Global RegexHistoricalMatch
Global RegexHistoricalMiss
Global RegexHistoricalOther
Global HistoricalEventsLV

; Predefine a coach object. The Trainer will redefine it. 
coach := {}

Gui MainGUI:Default

;;; First build the Coach tab 
Gui, Tab, Coach

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

;;; Now build the Historical tab
Gui, Tab, Historical

; Add regex search fields
Gui, Add, Edit, -WantReturn x12  y64 w50 h20 vRegexHistoricalSavings, 
Gui, Add, Edit, -WantReturn x62  y64 w180 h20 vRegexHistoricalWord,  
Gui, Add, Edit, -WantReturn x242 y64 w80 h20 vRegexHistoricalQwerd,  
Gui, Add, Edit, -WantReturn x322 y64 w80 h20 vRegexHistoricalChord,   
Gui, Add, Edit, -WantReturn x402 y64 w60 h20 vRegexHistoricalChordable,  
Gui, Add, Edit, -WantReturn x462 y64 w80 h20 vRegexHistoricalForm, 
Gui, Add, Edit, -WantReturn x542 y64 w50 h20 vRegexHistoricalPower, 
Gui, Add, Edit, -WantReturn x592 y64 w50 h20 vRegexHistoricalSaves, 
Gui, Add, Edit, -WantReturn x642 y64 w50 h20 vRegexHistoricalMatch, 
Gui, Add, Edit, -WantReturn x692 y64 w50 h20 vRegexHistoricalCMatch, 
Gui, Add, Edit, -WantReturn x742 y64 w50 h20 vRegexHistoricalMiss, 
Gui, Add, Edit, -WantReturn x792 y64 w50 h20 vRegexHistoricalOther, 
Gui, Add, Button, x838 y64 w90 h20 gHistoricalFilterHistoricalEvents, Filter

; Add the data ListView
Gui, Add, ListView, x12 y84 w916 h476 vHistoricalEventsLV, Savings|Word|Qwerd|Chord|Chordable|Form|Power|Saves|Matches|Chords|Misses|Other
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

HistoricalFilterHistoricalEvents() {
	global coach
	coach.filterHistoricalEvents()
}

class CoachViewport
{
	map := ""
	speedViewer := ""
	coachQueues := []
	interval := 1000
	odometer_interval := (15 * 60 * 1000)
	phrasePowerThreshold := 100
	tip_power_threshold := 1
	coachEvents := ComObjCreate("Scripting.Dictionary")
	lifetimeEvents := ComObjCreate("Scripting.Dictionary")
	phrases := ComObjCreate("Scripting.Dictionary")
	phrase_buffer := ""
	qwerds_buffer := ""
	logQueue := new Queue("CoachQueue")
	logVerbosity := 2
		
	odometerSession := ""
	odometerLifetime := ""
	
	__New(map, speedViewer)
	{
		this.map := map
		this.logVerbosity := this.map.qenv.properties.LoggingLevelCoach
		this.phrasePowerThreshold := this.map.qenv.properties.PhraseEnthusiasm
		this.speedViewer := speedViewer
		this.odometerSessionFile := this.map.qenv.personalDataFolder "\odometerSession.ssv"
		this.odometerLifetimeFile := this.map.qenv.personalDataFolder "\odometerLifetime.ssv"
		
		this.persistLifetimeOdometer()
		
        this.dequeue_timer := ObjBindMethod(this, "DequeueEvents")
        dequeue_timer := this.dequeue_timer
        SetTimer % dequeue_timer, % this.interval
		
        this.odometer_timer := ObjBindMethod(this, "saveSessionOdometer")
        odometer_timer := this.odometer_timer
        SetTimer % odometer_timer, % this.odometer_interval
		this.LogEvent(2, "Coach initialized")
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hSearchCoachEvents)
			this.filterCoachEvents()
	}
	
	filterCoachEvents() {
		local garbage
		Gui MainGUI:Default
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
		this.saveSessionOdometer()
	}
	
	
	filterHistoricalEvents() {
		local garbage
		Gui MainGUI:Default
		GuiControlGet RegexHistoricalSavings
		GuiControlGet RegexHistoricalWord
		GuiControlGet RegexHistoricalQwerd
		GuiControlGet RegexHistoricalChord
		GuiControlGet RegexHistoricalChordable
		GuiControlGet RegexHistoricalForm
		GuiControlGet RegexHistoricalPower
		GuiControlGet RegexHistoricalSaves
		GuiControlGet RegexHistoricalMatch
		GuiControlGet RegexHistoricalCMatch
		GuiControlGet RegexHistoricalMiss
		GuiControlGet RegexHistoricalOther
		
		;global SaveProgress
		
		
		this.logEvent(3, "RegexHistoricalSavings " RegexHistoricalSavings ", RegexHistoricalWord " RegexHistoricalWord ", RegexHistoricalQwerd " RegexHistoricalQwerd ", RegexHistoricalChord " RegexHistoricalChord ", RegexHistoricalChordable " RegexHistoricalChordable ", RegexHistoricalForm " RegexHistoricalForm ", RegexHistoricalPower " RegexHistoricalPower ", RegexHistoricalSaves " RegexHistoricalSaves ", RegexHistoricalMatch " RegexHistoricalMatch ", RegexHistoricalCMatch " RegexHistoricalCMatch ", RegexHistoricalMiss " RegexHistoricalMiss ", RegexHistoricalOther " RegexHistoricalOther)
		
		requiredMatchCount := 0
		requiredMatchCount += (RegexHistoricalSavings) ? 1 : 0
		requiredMatchCount += (RegexHistoricalWord) ? 1 : 0
		requiredMatchCount += (RegexHistoricalQwerd) ? 1 : 0
		requiredMatchCount += (RegexHistoricalChord) ? 1 : 0
		requiredMatchCount += (RegexHistoricalChordable) ? 1 : 0
		requiredMatchCount += (RegexHistoricalForm) ? 1 : 0
		requiredMatchCount += (RegexHistoricalPower) ? 1 : 0
		requiredMatchCount += (RegexHistoricalSaves) ? 1 : 0
		requiredMatchCount += (RegexHistoricalMatch) ? 1 : 0
		requiredMatchCount += (RegexHistoricalCMatch) ? 1 : 0
		requiredMatchCount += (RegexHistoricalMiss) ? 1 : 0
		requiredMatchCount += (RegexHistoricalOther) ? 1 : 0
		
		Gui, ListView, HistoricalEventsLV
		LV_Delete()
		
		for wordKey, garbage in this.lifetimeEvents {
			word := this.lifetimeEvents.item(wordKey)
			foundKey := 0
			foundKey += this.testField("RegexHistoricalSavings", wordKey, word.savings, RegexHistoricalSavings)
			foundKey += this.testField("RegexHistoricalWord", wordKey, word.word, RegexHistoricalWord)
			foundKey += this.testField("RegexHistoricalQwerd", wordKey, word.qwerd, RegexHistoricalQwerd)
			foundKey += this.testField("RegexHistoricalChord", wordKey, word.chord, RegexHistoricalChord)
			foundKey += this.testField("RegexHistoricalChordable", wordKey, word.chordable, RegexHistoricalChordable)
			foundKey += this.testField("RegexHistoricalForm", wordKey, word.form, RegexHistoricalForm)
			foundKey += this.testField("RegexHistoricalPower", wordKey, word.power, RegexHistoricalPower)
			foundKey += this.testField("RegexHistoricalSaves", wordKey, word.saves, RegexHistoricalSaves)
			foundKey += this.testField("RegexHistoricalMatch", wordKey, word.match, RegexHistoricalMatch)
			foundKey += this.testField("RegexHistoricalCMatch", wordKey, word.cmatch, RegexHistoricalCMatch)
			foundKey += this.testField("RegexHistoricalMiss", wordKey, word.miss, RegexHistoricalMiss)
			foundKey += this.testField("RegexHistoricalOther", wordKey, word.other, RegexHistoricalOther)
			;if (RegexHistoricalSavings) {
			;	if (RegExMatch(word.savings,RegexHistoricalSavings)) {
			;		this.logEvent(4, "RegexHistoricalSavings matched " wordKey)
			;		foundKeys[wordKey] := (foundKeys[wordKey]) ? foundKeys[wordKey] + 1 : 1
			;	}
			;}
		
			if (foundKey >= requiredMatchCount) {
				LV_Add(, word.savings, word.word, word.qwerd, word.chord, word.chordable, word.form, word.power, word.saves, word.match, word.cmatch, word.miss, word.other)
			}
		}
		this.saveSessionOdometer()
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
		eventKey := coachEvent.qwerd
		StringLower, eventKey, eventKey
		coachEvent.qwerd := eventKey
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
		if (coachEvent.endKey != "{Space}") {
			this.LogEvent(4, "Clearing phrase buffer with end key " coachEvent.endKey)
			this.phrase_buffer := ""
			this.qwerds_buffer := ""
		}
	}
	
	persistLifetimeOdometer() {
		this.LogEvent(2, "Persisting lifetime odometer")
		this.loadSessionOdometer()
		this.loadLifetimeOdometer()
		this.accrueLastSessionEventsToLifetime()
		this.saveLifetimeOdometer()
		this.coachEvents.RemoveAll
		this.LogEvent(2, "Finished persisting lifetime odometer")
	}
	
	loadSessionOdometer() {
		Loop,Read, % this.odometerSessionFile
		{
			if (A_Index = 1) {
				Continue 
			}
			; savings;word;qwerd;chord;form;power;saves;matches;chords;misses;other
			event_fields := StrSplit(A_LoopReadLine, ";")
			coaching := new CoachingEvent()
			coaching.savings := event_fields[1]
			coaching.word := event_fields[2]
			coaching.qwerd := event_fields[3]
			coaching.chord := event_fields[4]
			coaching.chordable := ""
			coaching.chorded := ""
			coaching.form := event_fields[5]
			coaching.saves := event_fields[7]
			coaching.power := event_fields[6]
			coaching.match := event_fields[8]
			coaching.cmatch := event_fields[9]
			coaching.miss := event_fields[10]
			coaching.other := event_fields[11]
			coaching.endKey := ""
			this.coachEvents.item(coaching.qwerd) := coaching
		}
		this.LogEvent(2, "Loaded last session coaching odometer " )
	}
	
	loadLifetimeOdometer() {
		Loop,Read, % this.odometerLifetimeFile
		{
			if (A_Index = 1) {
				Continue 
			}
			; savings;word;qwerd;chord;form;power;saves;matches;chords;misses;other
			event_fields := StrSplit(A_LoopReadLine, ";")
			coaching := new CoachingEvent()
			coaching.savings := event_fields[1]
			coaching.word := event_fields[2]
			coaching.qwerd := event_fields[3]
			coaching.chord := event_fields[4]
			coaching.chordable := ""
			coaching.chorded := ""
			coaching.form := event_fields[5]
			coaching.saves := event_fields[7]
			coaching.power := event_fields[6]
			coaching.match := event_fields[8]
			coaching.cmatch := event_fields[9]
			coaching.miss := event_fields[10]
			coaching.other := event_fields[11]
			coaching.endKey := ""
			this.lifetimeEvents.item(coaching.qwerd) := coaching
		}
		this.LogEvent(2, "Loaded current lifetime odometer " )
	}
	
	accrueLastSessionEventsToLifetime() {
		local
		global CoachingEvent
		for qwerd, garbage in this.coachEvents {
			sessionEvent := this.coachEvents.item(qwerd)
			if (! this.lifetimeEvents.item(qwerd).qwerd) {
				coaching := new CoachingEvent()
				coaching.word := sessionEvent.word
				coaching.qwerd := sessionEvent.qwerd
				coaching.chord := sessionEvent.chord
				coaching.chordable := sessionEvent.chordable
				coaching.chorded := sessionEvent.chorded
				coaching.form := sessionEvent.form
				coaching.saves := 0
				coaching.power := sessionEvent.power
				coaching.match := 0
				coaching.cmatch := 0
				coaching.miss := 0
				coaching.other := 0
				coaching.endKey := sessionEvent.key
				this.lifetimeEvents.item(qwerd) := coaching
			} 
			; accrue found values 
			this.lifetimeEvents.item(qwerd).savings += sessionEvent.savings
			this.lifetimeEvents.item(qwerd).saves += sessionEvent.saves
			this.lifetimeEvents.item(qwerd).match += sessionEvent.match
			this.lifetimeEvents.item(qwerd).cmatch += sessionEvent.cmatch
			this.lifetimeEvents.item(qwerd).miss += sessionEvent.miss
			this.lifetimeEvents.item(qwerd).other += sessionEvent.other
			; Update lifetime values from latest session values. 
			this.lifetimeEvents.item(qwerd).word := sessionEvent.word
			this.lifetimeEvents.item(qwerd).form := sessionEvent.form
			this.lifetimeEvents.item(qwerd).chord := sessionEvent.chord
			this.lifetimeEvents.item(qwerd).power := sessionEvent.power
			this.lifetimeEvents.item(qwerd).saves := sessionEvent.saves
		}
	}
	
	saveLifetimeOdometer() {
		local
		fileHandle := FileOpen(this.odometerLifetimeFile, "w")
		header := "savings;word;qwerd;chord;form;power;saves;matches;chords;misses;other`n"
		fileHandle.Write(header)
		
		for qwerd, garbage in this.lifetimeEvents {
			event := this.lifetimeEvents.item(qwerd)
			odometerline := event.savings ";" event.word ";" event.qwerd ";" event.chord ";" event.form ";" event.power ";" event.saves ";" event.match ";" event.cmatch ";" event.miss ";" event.other "`n"
			fileHandle.Write(odometerline)
		}
		
		fileHandle.Close()
	}
	
	saveSessionOdometer() {
		local
		fileHandle := FileOpen(this.odometerSessionFile, "w")
		header := "savings;word;qwerd;chord;form;power;saves;matches;chords;misses;other`n"
		fileHandle.Write(header)
		
		for qwerd, garbage in this.coachEvents {
			event := this.coachEvents.item(qwerd)
			odometerline := event.savings ";" event.word ";" event.qwerd ";" event.chord ";" event.form ";" event.power ";" event.saves ";" event.match ";" event.cmatch ";" event.miss ";" event.other "`n"
			fileHandle.Write(odometerline)
		}
		
		fileHandle.Close()
	}
	
	flashTip(coachEvent) {
		; Deprecated due to dashboard
		return
;		if (coachEvent.power < this.tip_power_threshold) {
;			return
;		}
;		CoordMode, ToolTip, Relative
;		;MsgBox, % "flashing " coachEvent.qwerd " as " this.map.qwerds.item(coachEvent.qwerd).dictionary " and got " unreliable
;		if (coachEvent.chordable = "active") {
;			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd " (" coachEvent.chord ")", 0, 0 ; ;A_CaretX, A_CaretY + 30
;		} else {
;			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= " coachEvent.qwerd, 0, 0 ;, A_CaretX, A_CaretY + 30
;		}
;		SetTimer, ClearToolTipCoaching, -5000
;		return 
;
;		ClearToolTipCoaching:
;		  ToolTip
;		return 
	}
	
	flashTip_chord(coachEvent) {
		return
;		CoordMode, ToolTip, Relative
;		;MsgBox, % "flashing chord " coachEvent.qwerd " as " this.map.qwerds.item(coachEvent.qwerd).dictionary " and got " unreliable
;		if (coachEvent.chordable = "active") {
;			Tooltip % coachEvent.word " " this.map.qwerds.item(coachEvent.qwerd).reliability "= ** " coachEvent.qwerd " (" coachEvent.chord ") **", 0, 0 ; ;A_CaretX, A_CaretY + 30
;		} 
;		SetTimer, ClearToolTipCoaching_chord, % (-1 * this.map.qenv.properties.CoachAheadTipDuration)
;		return 
;
;		ClearToolTipCoaching_chord:
;		  ToolTip
;		return 
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
