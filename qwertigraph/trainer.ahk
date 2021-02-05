#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

#Include classes\QwertigraphyEnvironment.ahk
#Include classes\DictionaryEntry.ahk
#Include classes\DictionaryMap.ahk
#Include classes\MappingEngine_InputHook.ahk
#Include classes\Queue.ahk
#Include classes\LogViewport.ahk
#Include classes\LoggingEvent.ahk
#Include classes\SpeedingEvent.ahk
#Include classes\SpeedViewport.ahk
#Include classes\QwertigraphyEnvironment.ahk

; Make the pretty icon
I_Icon = coach.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%

qenv := new QwertigraphyEnvironment()
map := new DictionaryMap(qenv)
engine := new MappingEngine_InputHook(map)

logViewer := new LogViewport()
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(engine.logQueue)
		
speedViewer := new SpeedViewport()
speedViewer.addQueue(engine.speedQueue)
		
coachViewer := new CoachViewport(map)
coachViewer.addQueue(engine.coachQueue)


engine.Start()

#Include *i personal.ahk

class CoachingEvent 
{
	word := ""
	qwerd := ""
	form := ""
	saves := 0
	power := 0
	match := 0
	miss := 0
	other := 0
	savings := 0
	endKey := ""
	
	__New()
	{
	}
}

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
class CoachViewport
{
	map := ""
	coachQueues := []
	interval := 1000
	coachEvents := ComObjCreate("Scripting.Dictionary")
	phrases := ComObjCreate("Scripting.Dictionary")
	phrase_buffer := ""
	qwerds_buffer := ""
	
	__New(map)
	{
		this.map := map
		
		Gui CoachGUI:Default
		; Add header text
		Gui, CoachGUI:Add, Text, x12  y9 w700  h20 , % "We can see what we can do better" 

		; Add regex search fields
		Gui, CoachGUI:Add, Edit, -WantReturn x12  y29 w50 h20 vRegexCoachSavings, 
		Gui, CoachGUI:Add, Edit, -WantReturn x62  y29 w120 h20 vRegexCoachWord,  
		Gui, CoachGUI:Add, Edit, -WantReturn x182 y29 w100 h20 vRegexCoachQwerd,  
		Gui, CoachGUI:Add, Edit, -WantReturn x282 y29 w100 h20 vRegexCoachForm, 
		Gui, CoachGUI:Add, Edit, -WantReturn x382 y29 w40 h20 vRegexCoachPower, 
		Gui, CoachGUI:Add, Edit, -WantReturn x422 y29 w25 h20 vRegexCoachSaves, 
		Gui, CoachGUI:Add, Edit, -WantReturn x447 y29 w25 h20 vRegexCoachMatch, 
		Gui, CoachGUI:Add, Edit, -WantReturn x472 y29 w25 h20 vRegexCoachMiss, 
		Gui, CoachGUI:Add, Edit, -WantReturn x497 y29 w47 h20 vRegexCoachOther, 
		Gui, CoachGUI:Add, Button, Default x544 y29 w90 h20 hwndhSearchCoachEvents, Search
		this.hSearchCoachEvents := hSearchCoachEvents
		OnMessage(0x111, this.WmCommand := this.WmCommand.bind(this), 2)

		; Add the data ListView
		Gui, CoachGUI:Add, ListView, x12 y49 w532 h420 vCoachEventsLV, Savings|Word|Qwerd|Form|`%|#|+|-|0
		LV_ModifyCol(1, "Integer")  ; For sorting, indicate columns are integer.
		LV_ModifyCol(5, "Float")  
		LV_ModifyCol(6, "Integer")  
		LV_ModifyCol(7, "Integer")  
		LV_ModifyCol(8, "Integer")  
		LV_ModifyCol(9, "Integer")  
		LV_ModifyCol(1, 50)
		LV_ModifyCol(2, 120)
		LV_ModifyCol(3, 100)
		LV_ModifyCol(4, 100)
		LV_ModifyCol(5, 40)
		LV_ModifyCol(6, 25)
		LV_ModifyCol(7, 25)
		LV_ModifyCol(8, 25)
		LV_ModifyCol(9, 25)

		; Generated using SmartGUI Creator 4.0
		Gui, Show, x262 y118 h560 w660, % "Coaching Viewer"
		
        this.timer := ObjBindMethod(this, "DequeueEvents")
        timer := this.timer
        SetTimer % timer, % this.interval
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hSearchCoachEvents)
			this.SearchCoachEvents()
	}
	
	SearchCoachEvents() {
		Gui CoachGUI:Default
		LV_Delete()
		For eventkey, garbage in this.coachEvents {
			value := this.coachEvents.item(eventkey)
			LV_Add(, value.savings, value.word, value.qwerd, value.form, value.power, value.saves, value.match, value.miss, value.other)
		}
	}
	
	DequeueEvents() {
		Gui CoachGUI:Default
		For index, coachQueue in this.coachQueues {
			Loop, % coachQueue.getSize() {
				coachEvent := coachQueue.dequeue()
				if (not coachEvent.word) {
					; Ignore null words
					Continue
				}
				this.coachItem(coachEvent)
				this.coachPhrasing(coachEvent)
			}
		}
	}
	
	coachItem(coachEvent) {
		eventKey := coachEvent.word
		StringLower, eventKey, eventKey
		if (not this.coachEvents.item(eventKey)) {
			this.coachEvents.item(eventKey) := coachEvent
		} else {
			this.coachEvents.item(eventKey).match += coachEvent.match
			this.coachEvents.item(eventKey).miss += coachEvent.miss
			this.coachEvents.item(eventKey).other += coachEvent.other
		}
		this.coachEvents.item(eventKey).savings += coachEvent.saves
	}
	
	addQueue(coachQueue) { 
		this.coachQueues.Push(coachQueue)
	}
	
	coachPhrasing(coachEvent) {
		this.phrase_buffer .= " " coachEvent.word
		this.qwerds_buffer .= " " coachEvent.qwerd
		words := StrSplit(this.phrase_buffer, " ")
		current_phrase := words[words.MaxIndex()]
		Loop, % words.MaxIndex() {
			word_index := words.MaxIndex() - A_Index
			current_phrase := words[word_index] " " current_phrase
			if (this.phrases.item(current_phrase)) {
				this.phrases.item(current_phrase) += 1
			} else {
				this.phrases.item(current_phrase) := 1
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
			}
		}
		if (coachEvent.endKey != "Space") {
			this.phrase_buffer := ""
			this.qwerds_buffer := ""
		}
	}
}

^Space::
^Enter::
^Tab::
^.::
^,::
^/::
^;::
^[::
	Send, % "{" SubStr(A_ThisHotkey, 2, StrLen(A_ThisHotkey) - 1) "}"
	return