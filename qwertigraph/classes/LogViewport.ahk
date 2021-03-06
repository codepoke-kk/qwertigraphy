
global RegexWhere
global RegexWhen
global RegexWhat
global RegexHow
global LogEventsLV

logViewer := {}

Gui, Tab, Logs
; Add regex search fields
Gui, Add, Edit, -WantReturn x12  y64 w90 h20 vRegexWhere,  
Gui, Add, Edit, -WantReturn x102 y64 w100  h20 vRegexWhen,  
Gui, Add, Edit, -WantReturn x202 y64 w576  h20 vRegexWhat, 
Gui, Add, Edit, -WantReturn x778 y64 w60  h20 vRegexHow,
Gui, Add, Button, Default x838 y64 w90 h20 gLogViewerFilterLogEvents, Filter

; Add the data ListView
Gui, Add, ListView, x12 y84 w916 h476 vLogEventsLV, Where|When|What|How
LV_ModifyCol(4, "Integer")  ; For sorting, indicate that the Usage column is an integer.
LV_ModifyCol(1, 90)
LV_ModifyCol(2, 100)
LV_ModifyCol(3, 576)
LV_ModifyCol(4, 30)

LogViewerFilterLogEvents() {
	global logViewer
	logViewer.filterLogEvents()
}

class LogViewport
{
	logQueues := []
	interval := 1000
	logEvents := []
	
	__New()
	{
		
        this.timer := ObjBindMethod(this, "DequeueEvents")
        timer := this.timer
        SetTimer % timer, % this.interval
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hFilterLogEvents)
			this.filterLogEvents()
	}
	
	filterLogEvents() {
		GuiControlGet RegexWhere
		GuiControlGet RegexWhen
		GuiControlGet RegexWhat
		GuiControlGet RegexHow
		
		requiredMatchCount := 0
		requiredMatchCount += (RegexWhere) ? 1 : 0
		requiredMatchCount += (RegexWhen) ? 1 : 0
		requiredMatchCount += (RegexWhat) ? 1 : 0
		requiredMatchCount += (RegexHow) ? 1 : 0
		
		Gui, ListView, LogEventsLV
		LV_Delete()
		
		for logEventIndex, logEvent in this.logEvents {
			foundKey := 0
			foundKey += this.testField("RegexWhere", A_Index, logEvent.where, RegexWhere)
			foundKey += this.testField("RegexWhen", A_Index, logEvent.when, RegexWhen)
			foundKey += this.testField("RegexWhat", A_Index, logEvent.what, RegexWhat)
			foundKey += this.testField("RegexHow", A_Index, logEvent.how, RegexHow)
		
			if (foundKey >= requiredMatchCount) {
				LV_Add(, logEvent.where, logEvent.when, logEvent.what, logEvent.how)
			}
		}
	}
	
	testField(fieldName,rowNum,haystack,needle) {
		if (needle) {
			if (RegExMatch(haystack, "i)" needle)) {
				return 1
			}
		}
		return 0
	}
	
	
	DequeueEvents() {
		Gui, ListView, LogEventsLV
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