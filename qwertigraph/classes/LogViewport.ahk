
global RegexWhere
global RegexWhen
global RegexWhat
global RegexHow
global LogEventsLV

class LogViewport
{
	logQueues := []
	interval := 1000
	logEvents := []
	
	__New()
	{
		
		Gui LogGUI:Default
		; Add header text
		Gui, LogGUI:Add, Text, x12  y9 w700  h20 , % "We can watch the log" 

		; Add regex search fields
		Gui, LogGUI:Add, Edit, -WantReturn x12  y29 w90 h20 vRegexWhere,  
		Gui, LogGUI:Add, Edit, -WantReturn x102 y29 w90  h20 vRegexWhen,  
		Gui, LogGUI:Add, Edit, -WantReturn x192 y29 w570  h20 vRegexWhat, 
		Gui, LogGUI:Add, Edit, -WantReturn x762 y29 w60  h20 vRegexHow,
		Gui, LogGUI:Add, Button, Default x812 y29 w90 h20 hwndhSearchLogEvents, Search
		this.hSearchLogEvents := hSearchLogEvents
		OnMessage(0x111, this.WmCommand := this.WmCommand.bind(this), 2)

		; Add the data ListView
		;Gui, LogGUI:Add, ListView, x12 y49 w800 h420 vLogEventsLV gLogEventsLV, Where|When|What|How
		Gui, LogGUI:Add, ListView, x12 y49 w800 h420 vLogEventsLV, Where|When|What|How
		LV_ModifyCol(4, "Integer")  ; For sorting, indicate that the Usage column is an integer.
		LV_ModifyCol(1, 90)
		LV_ModifyCol(2, 90)
		LV_ModifyCol(3, 570)
		LV_ModifyCol(4, 30)

		; Generated using SmartGUI Creator 4.0
		Gui, Show, x262 y118 h560 w936, % "Log Viewer"
		
        this.timer := ObjBindMethod(this, "DequeueEvents")
        timer := this.timer
        SetTimer % timer, % this.interval
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hSearchLogEvents)
			this.SearchLogEvents()
	}
	
	SearchLogEvents() {
		Msgbox, % "Search!"
	}
	
	DequeueEvents() {
		Gui LogGUI:Default
		For index, logQueue in this.logQueues {
			Loop, % logQueue.getSize() {
				logEvent := logQueue.dequeue()
				this.logEvents.Push(logEvent)
				LV_Add(, logEvent.where, logEvent.when, logEvent.what, logEvent.how)
			}
		}
	}
	
	addQueue(logQueue) { 
		this.logQueues.Push(logQueue)
	}
}