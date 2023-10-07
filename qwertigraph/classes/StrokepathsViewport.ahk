
global StrokepathsTitle
global StrokepathsLV
global RegexPattern
global RegexPath
global EditPattern
global EditPath
global SaveStrokepaths

strokePaths := {}

Gui MainGUI:Default
Gui, Tab, Strokes
; Add regex search fields
Gui, Add, Edit, -WantReturn x12 y64 w645 h20 vRegexPath,
Gui, Add, Edit, -WantReturn x657 y64 w180  h20 vRegexPattern,
Gui, Add, Button, x838 y64 w90 h20 gStrokerSearchStrokepathEntries, Search

; Add the data ListView
Gui, Add, ListView, -ReadOnly x12 y84 w820 h456 vStrokepathsLV gStrokepathsLV, Strokepath|Pattern
LV_ModifyCol(1, 645)
LV_ModifyCol(2, 175)

; Add edit fields and controls
Gui, Add, Edit, x12 y540 w645  h20 vEditPath,
Gui, Add, Edit, x657 y540 w180  h20 vEditPattern,
Gui, Add, Button, x838 y130 w90 h20 gStrokerEditRow, Edit
Gui, Add, Button, x838 y150 w90 h20 gStrokerDeleteRow, Delete
Gui, Add, Button, x838 y539 w90 h20 gStrokerCommitStrokepath, Commit
Gui, Add, Button, x838 y500 w90 h30 gStrokerSaveStrokepaths vStrokerSaveStrokepaths , Save


StrokerSearchStrokepathEntries() {
	global stroker
	stroker.SearchStrokepathEntries()
}
StrokerCommitStrokepath() {
	global stroker
	stroker.commitStrokepath()
}
StrokerSaveStrokepaths() {
	global stroker
	stroker.saveStrokepaths()
}

StrokepathsLV() {
	global stroker
	Gui MainGUI:Default
    stroker.logEvent(2, "Listview event " A_GuiEvent " on " A_EventInfo)
    if (A_GuiEvent = "DoubleClick") {
        stroker.prepareStrokepath(A_EventInfo)
    }
    if (A_GuiEvent = "e") {
		Gui, Listview, StrokepathsLV
        ;LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		LV_GetText(path, A_EventInfo, 1)
		LV_GetText(pattern, A_EventInfo, 2)
		stroker.logEvent(3, "Listview in-place edit of " pattern " to  " path)
		stroker.qenv.strokepaths.item(pattern) := {"pattern": pattern, "path": path}
		stroker.dashboard.visualizeQueue()
		; Reload the search view with the new value
		stroker.searchMapEntries()
        ;stroker.logEvent(3, "Listview in-place edit to  " RowText)
        ;Msgbox, % "You edited row " A_EventInfo " to: " RowText
    }
}


StrokerEditRow() {
	global stroker
	Gui MainGUI:Default
	Gui, ListView, StrokepathsLV
	stroker.logEvent(1, "Stroker Listview ContextMenu edit")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		stroker.logEvent(1, "Listview edit event with no row selected")
        return
	}
    stroker.logEvent(3, "Listview context edit event on row " FocusedRowNumber)
    stroker.prepareStrokepath(FocusedRowNumber)
}
StrokerDeleteRow() {
	global stroker
	Gui MainGUI:Default
	Gui, ListView, StrokepathsLV
	stroker.logEvent(1, "Listview ContextMenu edit")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		stroker.logEvent(1, "Listview edit event with no row selected")
        return
	}
    stroker.logEvent(3, "Listview context delete event on row " FocusedRowNumber)
    stroker.prepareStrokepath(FocusedRowNumber)
    stroker.deleteStrokepath()
	stroker.SearchStrokepathEntries()
}

class StrokepathsViewport
{
	qenv := ""
	logQueue := new Queue("StrokerQueue")
	logVerbosity := 1

	__New(qenv, dashboard)
	{
		this.qenv := qenv
		this.dashboard := dashboard
		this.logVerbosity := 1 ; this.map.qenv.properties.LoggingLevelStroker

		this.logEvent(3, "Initializing strokepaths " this.qenv.strokepaths.Count)

		Gui, ListView, StrokerLV
		for strokepathsKey, strokepath in this.qenv.strokepaths {
			this.logEvent(4, "Strokepath is " this.qenv.strokepaths.item(strokepathsKey).sorter)
			strokepath := this.qenv.strokepaths.item(strokepathsKey)
			LV_Add(, strokepath.path, strokepath.pattern)
		}
	}

	ListViewEvent() {
		Gui MainGUI:Default
		this.logEvent(2, "Listview event " A_GuiEvent " on " A_EventInfo)
		if (A_GuiEvent = "DoubleClick") {
			this.prepareStrokepath(A_EventInfo)
		}
		if (A_GuiEvent = "e") {
			LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
			LV_GetText(path, A_EventInfo, 1)
			LV_GetText(pattern, A_EventInfo, 2)
			this.logEvent(3, "Listview in-place edit of " pattern " to  " path)
			this.qenv.strokepaths.item(pattern) := {"pattern": pattern, "path": path}
			this.dashboard.visualizeQueue()
			; Reload the search view with the new value
			this.searchMapEntries()
		}
	}

	SearchStrokepathEntries() {
		local
		Gui MainGUI:Default
		Gui, Tab, Strokes
		GuiControlGet RegexPath
		GuiControlGet RegexPattern

		this.logEvent(2, "Searching RegexPath " RegexPath ", RegexPattern " RegexPattern)

		requiredMatchCount := 0
		requiredMatchCount += (RegexPath) ? 1 : 0
		requiredMatchCount += (RegexPattern) ? 1 : 0
		foundKeys := {}
		for strokepathKey in this.qenv.strokepaths {
			StringLower, strokepathKey, strokepathKey
			if (foundKeys[strokepathKey]) {
				; Must be case insensitive in this searching, and can only add found count once per key
				continue
			}
			strokepath := this.qenv.strokepaths.item(strokepathKey)
			if (RegexPath) {
				if (RegExMatch(strokepath.path,RegexPath)) {
					this.logEvent(4, "RegexPath matched " strokepathKey)
					foundKeys[strokepathKey] := (foundKeys[strokepathKey]) ? foundKeys[strokepathKey] + 1 : 1
				}
			}
			if (RegexPattern) {
				if (RegExMatch(strokepath.pattern,RegexPattern)) {
					this.logEvent(4, "RegexPattern matched " strokepathKey)
					foundKeys[strokepathKey] := (foundKeys[strokepathKey]) ? foundKeys[strokepathKey] + 1 : 1
				}
			}
		}


		Gui, ListView, StrokepathsLV
		LV_Delete()
		foundCount := 0
		for foundKey, count in foundKeys {
			if (foundKeys[foundKey] = requiredMatchCount) {
				strokepath := this.qenv.strokepaths.item(foundKey)
				foundCount += 1
                ; this.logEvent(3, "Qwerd's chordable is " qwerd.chordable ", but the chord's chordable is " this.map.chords.item(qwerd.chord).chordable)
				LV_Add(, strokepath.path, strokepath.pattern)
			} else {
				this.logEvent(3, foundKey " matched " foundKeys[foundKey] " times, not " requiredMatchCount)
			}
		}
		this.logEvent(3, "Found " foundCount " matches")
	}

	prepareStrokepath(RowNumber) {
        local
		Gui MainGUI:Default
		this.logEvent(2, "Preparing edit for ListView row " RowNumber)

		Gui, ListView, StrokepathsLV
		; Get the data from the edited row
		LV_GetText(EditPath, RowNumber, 1)
		LV_GetText(EditPattern, RowNumber, 2)

		; Push the data into the editing fields
		GuiControl, Text, EditPath, %EditPath%
		GuiControl, Text, EditPattern, %EditPattern%
	}

	commitStrokepath() {
        local
		Gui MainGUI:Default
		this.logEvent(3, "Commiting edit to strokepath")

		; Grab values the user has edited and wants to commit
		GuiControlGet path, , EditPath
		GuiControlGet pattern, , EditPattern

		newEntryEsv := pattern "=" path
		this.logEvent(2, "Commiting fields: " newEntryEsv)
		this.qenv.strokepaths.item(pattern) := {"pattern": pattern, "path": path}
		this.dashboard.visualizeQueue()
		; Reload the search view with the new value
		this.searchMapEntries()
	}

	saveStrokepaths() {
		this.qenv.saveStrokepaths()
		this.logEvent(3, "Saved strokepaths")
	}

	deleteStrokepath() {
		Gui MainGUI:Default
		; Grab values the user has edited and wants to commit
		GuiControlGet strokepathKey, , EditPattern

		this.logEvent(3, "Deleting " strokepathKey)
		this.qenv.strokepaths.remove(strokepathKey)
	}

	LogEvent(verbosity, message)
	{
		if (verbosity <= this.logVerbosity)
		{
			event := new LoggingEvent("stroker",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
