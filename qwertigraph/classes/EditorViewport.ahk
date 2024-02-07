
global EditorTitle
global EditorLV
global RegexDict
global RegexWord
global RegexForm
global RegexQwerd
global RegexKeyer
global RegexUsage
global RegexChord
global EditDict
global EditWord
global EditForm
global EditQwerd
global EditKeyer
global EditUsage
global EditChord
global EditForm
global AutoGenChords
global SaveDictionaries
global DictionaryDropDown
global SaveProgress
global BackupCount

editor := {}
DictionaryDropDown := {}


Gui MainGUI:Default
Gui, Tab, Editor
; Add regex search fields
Gui, Add, Edit, -WantReturn x12  y64 w160 h20 vRegexWord,
Gui, Add, Edit, -WantReturn x172 y64 w90  h20 vRegexForm,
Gui, Add, Edit, -WantReturn x262 y64 w90  h20 vRegexQwerd,
Gui, Add, Edit, -WantReturn x352 y64 w30  h20 vRegexKeyer,
Gui, Add, Edit, -WantReturn x382 y64 w80 h20 vRegexChord,
Gui, Add, Edit, -WantReturn x462 y64 w80 h20 vRegexChordable,
Gui, Add, Edit, -WantReturn x542 y64 w60  h20 vRegexUsage,
Gui, Add, Edit, -WantReturn x602 y64 w236 h20 vRegexDict,
Gui, Add, Button, Default x838 y64 w90 h20 gEditorSearchMapEntries, Search

; Add the data ListView
Gui, Add, ListView, x12 y84 w826 h456 vEditorLV gEditorLV, Word|Form|Qwerd|Keyer|Chord|Chordable|Usage|Dictionary
LV_ModifyCol(7, "Integer")  ; For sorting, indicate that the Usage column is an integer.
LV_ModifyCol(1, 160)
LV_ModifyCol(2, 90)
LV_ModifyCol(3, 90)
LV_ModifyCol(4, 30)
LV_ModifyCol(5, 80)
LV_ModifyCol(6, 80)
LV_ModifyCol(7, 60)
LV_ModifyCol(8, 216) ; 3 pixels short to avoid the h_scrollbar

; Add edit fields and controls
Gui, Add, Edit, x12  y540 w140 h20 vEditWord,
Gui, Add, Button, x152 y540 w20 h20 gEditorHone, H>
Gui, Add, Edit, x172 y540 w70  h20 vEditForm,
Gui, Add, Button, x242 y540 w20 h20 gEditorAutoQwerdForm, L>
Gui, Add, Edit, x262 y540 w90  h20 vEditQwerd,
Gui, Add, Button, x352 y540 w20 h20 gEditorAutoKey, K>
Gui, Add, Edit, x372 y540 w30  h20 vEditKeyer,
Gui, Add, Button, x402 y540 w20 h20 gEditorAutoChord, C>
Gui, Add, Edit, x422 y540 w50 h20 vEditChord,
Gui, Add, Edit, x472 y540 w80 h20 Disabled vEditChordable,
Gui, Add, Edit, x552 y540 w50  h20 vEditUsage,
Gui, Add, DropDownList, x602 y540 w236 r5 vEditDict, %dictionaryDropDown%
Gui, Add, Button, x838 y539 w90 h20 gEditorCommitEdit, Commit
Gui, Add, Text, x838 y480 w90 h30 vEditsStatus, Edits: None
Gui, Add, Button, x838 y500 w90 h30 gEditorSaveDictionaries vSaveDictionaries , Save
;Disabled
;Gui, Add, Progress, x12 y545 w700 h5 cOlive vSaveProgress, 1

; Add checkbox controls
;Gui, Add, CheckBox, x815 y49 w130 h20 vAutoGenChords gAutoGenChords Checked, AutoGenerate Chords
Gui, Add, Button, x838 y90 w90 h20 gEditorOpenPersonalizations, Personalizations
Gui, Add, Button, x838 y130 w90 h20 gEditorEditRow, Edit
Gui, Add, Button, x838 y150 w90 h20 gEditorDeleteRow, Delete
Gui, Add, Button, x838 y170 w90 h20 gEditorCreateRow_S, Add S
Gui, Add, Button, x838 y190 w90 h20 gEditorCreateRow_D, Add D
Gui, Add, Button, x838 y210 w90 h20 gEditorCreateRow_G, Add G
Gui, Add, Button, x838 y230 w90 h20 gEditorCreateRow_T, Add T
Gui, Add, Button, x838 y250 w90 h20 gEditorCreateRow_R, Add R
Gui, Add, Button, x838 y270 w90 h20 gEditorCreateRow_LY, Add LY
Gui, Add, Button, x838 y290 w90 h20 gEditorCreateRow_ION, Add ION
Gui, Add, Button, x838 y310 w90 h20 gEditorCreateRow_ES, Add ES
Gui, Add, Button, x838 y330 w90 h20 gEditorCreateRow_SDG, Add S+D+G

EditorSearchMapEntries() {
	global editor
	editor.SearchMapEntries()
}
EditorHone() {
	global editor
	editor.hone()
}
EditorAutoQwerdForm() {
	global editor
	editor.AutoQwerdForm()
}
EditorAutoKey() {
	global editor
	editor.AutoKey()
}
EditorAutoChord() {
	global editor
	editor.AutoChord()
}
EditorOpenPersonalizations() {
	global editor
	editor.OpenPersonalizations()
}
EditorCommitEdit() {
	global editor
	editor.commitEdit()
}
EditorSaveDictionaries() {
	global editor
	editor.saveDictionaries()
}

EditorLV() {
	global editor
	Gui MainGUI:Default
    editor.logEvent(2, "Listview event " A_GuiEvent " on " A_EventInfo)
    if (A_GuiEvent = "DoubleClick") {
        editor.prepareEdit(A_EventInfo)
    }
    if (A_GuiEvent = "e") {
		Gui, Listview, EditorLV
        LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
        editor.logEvent(3, "Listview in-place edit to  " RowText)
        Msgbox, % "You edited row " A_EventInfo " to: " RowText
    }
}


EditorEditRow() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
	editor.logEvent(1, "Listview ContextMenu edit")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
}
EditorDeleteRow() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
	editor.logEvent(1, "Listview multideletion event on " LV_GetCount("S") " rows")
	RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
	Loop
	{
		RowNumber := LV_GetNext(RowNumber)
		if not RowNumber {
			break
		}
		editor.logEvent(2, "Deleting row number " RowNumber )
		LV_GetText(qwerdKey, RowNumber, 3)
		editor.logEvent(2, "Found qwerd " qwerdKey)
		editor.prepareEdit(RowNumber)
		editor.map.deleteQwerdFromMaps(qwerdKey)
	}
	editor.SearchMapEntries()
}
EditorCreateRow_S() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding S on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("s", "-s", "s", "s")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_ES() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding ES on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("es", "-s", "s", "s")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_G() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding G on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("ing", "-\-h", "g", "g")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_D() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding D on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("ed", "-d", "d", "d")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_T() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding T on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("ed", "-t", "t", "t")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_R() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding R on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("er", "-r", "r", "r")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_LY() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding LY on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("ly", "-e", "e", "e")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_ION() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}
    editor.logEvent(3, "Listview context edit event adding ION on row " FocusedRowNumber)
    editor.prepareEdit(FocusedRowNumber)
    editor.addValueToEditFields("ion", "-sh", "z", "z")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}
EditorCreateRow_SDG() {
	global editor
	Gui MainGUI:Default
	Gui, ListView, EditorLV
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber { ; No row is focused.
		editor.logEvent(1, "Listview edit event with no row selected")
        return
	}

    editor.logEvent(2, "Getting data from ListView from row " FocusedRowNumber)

    ; Get the data from the edited row
    LV_GetText(EditWord, FocusedRowNumber, 1)
    LV_GetText(EditForm, FocusedRowNumber, 2)
    LV_GetText(EditQwerd, FocusedRowNumber, 3)
    LV_GetText(EditKeyer, FocusedRowNumber, 4)
    LV_GetText(EditChord, FocusedRowNumber, 5)
    LV_GetText(EditChordable, FocusedRowNumber, 6)
    LV_GetText(EditUsage, FocusedRowNumber, 7)
    LV_GetText(EditDict, FocusedRowNumber, 8)

    editor.logEvent(3, "Listview context edit event adding S+D+G on row " FocusedRowNumber)
    editor.prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict)
    editor.addValueToEditFields("s", "-s", "s", "s")
    editor.autoChord()
	editor.commitEdit()
    editor.prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict)
    editor.addValueToEditFields("ed", "-d", "d", "d")
    editor.autoChord()
	editor.commitEdit()
    editor.prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict)
    editor.addValueToEditFields("ing", "-\-h", "g", "g")
    editor.autoChord()
	editor.commitEdit()
	editor.SearchMapEntries()
}

class EditorViewport
{
	map := ""
	logQueue := new Queue("EditorQueue")
	logVerbosity := 2
	keyers := Array("","o","u","i","e","a","w","y")

	__New(map)
	{
		this.map := map
		this.qenv := this.map.qenv
		this.logVerbosity := this.map.qenv.properties.LoggingLevelEditor
        this.editsCount := 0
		DictionaryDropDown := map.dictionaryPickList

	}

	listViewEvent() {

		Gui MainGUI:Default
		this.logEvent(2, "Listview event " A_GuiEvent " on " A_EventInfo)
		if (A_GuiEvent = "DoubleClick") {
			this.prepareEdit(A_EventInfo)
		}
		if (A_GuiEvent = "e") {
			LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
			this.logEvent(3, "Listview in-place edit to  " RowText)
			Msgbox, % "You edited row " A_EventInfo " to: " RowText
		}
	}

	searchMapEntries() {
		local
		Gui MainGUI:Default
		GuiControlGet RegexDict
		GuiControlGet RegexWord
		GuiControlGet RegexForm
		GuiControlGet RegexQwerd
		GuiControlGet RegexKeyer
		GuiControlGet RegexChord
		GuiControlGet RegexChordable
		GuiControlGet RegexUsage

		;global SaveProgress


		this.logEvent(2, "RegexWord " RegexWord ", RegexForm " RegexForm ", RegexQwerd " RegexQwerd ", RegexKeyer " RegexKeyer ", RegexChord " RegexChord ", RegexChordable " RegexChordable ", RegexUsage " RegexUsage ", RegexDict " RegexDict )

		requiredMatchCount := 0
		requiredMatchCount += (RegexWord) ? 1 : 0
		requiredMatchCount += (RegexForm) ? 1 : 0
		requiredMatchCount += (RegexQwerd) ? 1 : 0
		requiredMatchCount += (RegexChord) ? 1 : 0
		requiredMatchCount += (RegexChordable) ? 1 : 0
		requiredMatchCount += (RegexKeyer) ? 1 : 0
		requiredMatchCount += (RegexUsage) ? 1 : 0
		requiredMatchCount += (RegexDict) ? 1 : 0
		foundKeys := {}
		for loopQwerdKey in this.map.qwerds {
			StringLower, loopQwerdKey, loopQwerdKey
			if (foundKeys[loopQwerdKey]) {
				; Must be case insensitive in this searching
				continue
			}
			qwerd := this.map.qwerds.item(loopQwerdKey)
			if (RegexDict) {
				if (RegExMatch(qwerd.dictionary,RegexDict)) {
					this.logEvent(4, "RegexDict matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexWord) {
				if (RegExMatch(qwerd.word,RegexWord)) {
					this.logEvent(4, "RegexWord matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexForm) {
				if (RegExMatch(qwerd.form,RegexForm)) {
					this.logEvent(4, "RegexForm matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexQwerd) {
				if (RegExMatch(qwerd.qwerd,RegexQwerd)) {
					this.logEvent(4, "RegexQwerd matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexKeyer) {
				if (RegExMatch(qwerd.keyer,RegexKeyer)) {
					this.logEvent(4, "RegexKeyer matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexChord) {
				if (RegExMatch(qwerd.chord,RegexChord)) {
					this.logEvent(4, "RegexChord matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexChordable) {
				if (RegExMatch(qwerd.chordable,RegexChordable)) {
					this.logEvent(4, "RegexChordable matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
			if (RegexUsage) {
				if (RegExMatch(qwerd.usage,RegexUsage)) {
					this.logEvent(4, "RegexUsage matched " loopQwerdKey)
					foundKeys[loopQwerdKey] := (foundKeys[loopQwerdKey]) ? foundKeys[loopQwerdKey] + 1 : 1
				}
			}
		}


		Gui, ListView, EditorLV
		LV_Delete()
		foundCount := 0
		for foundKey, count in foundKeys {
			if (foundKeys[foundKey] = requiredMatchCount) {
				qwerd := this.map.qwerds.item(foundKey)
				foundCount += 1
                ; this.logEvent(3, "Qwerd's chordable is " qwerd.chordable ", but the chord's chordable is " this.map.chords.item(qwerd.chord).chordable)
				LV_Add(, qwerd.word, qwerd.form, qwerd.qwerd, qwerd.keyer, qwerd.chord, qwerd.chordable, qwerd.usage, qwerd.dictionary)
			} else {
				this.logEvent(3, foundKey " matched " foundKeys[foundKey] " times, not " requiredMatchCount)
			}
		}
		this.logEvent(1, "Found " foundCount " matches")
	}

	hone() {
        local
		global greggdict
		Gui MainGUI:Default
		GuiControlGet word, , EditWord

		this.logEvent(3, "Honing " word)

		; Lowercase the whole word
		StringLower, loweredword, word
        greggdict.LogEvent(1, "Seeking greggdicts match for " loweredword " as " greggdict.greggdicts.item(loweredword).link " at " greggdict.greggdicts.item(loweredword).x "," greggdict.greggdicts.item(loweredword).y)

		wordbuffer := loweredword
		transformed := false
		Loop
		{
			greggdict.LogEvent(1, "Looping with " wordbuffer)
			if (greggdict.greggdicts.item(wordbuffer).x) {
				break
			}
			wordbuffer := SubStr(wordbuffer, 1, StrLen(wordbuffer) -1)
			if (StrLen(wordbuffer) < 1) {
				greggdict.LogEvent(1, "Fully failed to match " loweredword)
				wordbuffer := loweredword
				break
			}
			transformed := true
		}

        greggdict.LogEvent(1, "Search started with " loweredword " and ended using " wordbuffer " and transformation required was " transformed)

		if (greggdict.greggdicts.item(wordbuffer).x) {
			link := "file:///" A_ScriptDir "/greggdict/pages/honepad.html?page=" greggdict.greggdicts.item(wordbuffer).page ".png`&x=" greggdict.greggdicts.item(wordbuffer).x "`&y=" greggdict.greggdicts.item(wordbuffer).y "`&word=" loweredword "`&transformed=" transformed
		} else {
			link := "file:///" A_ScriptDir "/greggdict/pages/404.html?word=" wordbuffer
	}
		Run, msedge.exe "%link%",, UseErrorLevel

	}
	autoQwerdForm() {
        local
		Gui MainGUI:Default
		GuiControlGet form, , EditForm
		GuiControlGet word, , EditWord

		this.logEvent(3, "Generating auto qwerd for " form)

		; Lowercase the whole word
		StringLower, qwerd, form

		; Vowels
		qwerd := RegexReplace(qwerd, "ea", "e")
		qwerd := RegexReplace(qwerd, "ao", "w")
		qwerd := RegexReplace(qwerd, "au", "w")
		qwerd := RegexReplace(qwerd, "eu", "u")

		; Consonant sets
		if (RegexMatch(word, "x")) {
			qwerd := RegexReplace(qwerd, "es", "x")
		}
		if (RegexMatch(word, "qu")) {
			qwerd := RegexReplace(qwerd, "k", "q")
		}
		qwerd := RegexReplace(qwerd, "th", "h")
		qwerd := RegexReplace(qwerd, "ch", "c")
		qwerd := RegexReplace(qwerd, "sh", "z")

		; Prefixes
		qwerd := RegexReplace(qwerd, "pr(e|o)", "pr")
		qwerd := RegexReplace(qwerd, "per", "pr")

		qwerd := RegexReplace(qwerd, "-", "")
		qwerd := RegexReplace(qwerd, "\d", "")
		qwerd := RegexReplace(qwerd, "\W", "")

		GuiControl, Text, EditQwerd, %qwerd%

	}

	autoKey() {
        local
		Gui MainGUI:Default
		GuiControlGet word, , EditWord
		GuiControlGet qwerd, , EditQwerd
		GuiControlGet keyer, , EditKeyer
		GuiControlGet dict, , EditDict

		this.logEvent(3, "Mapping to dict " dict)
		dictionary := this.map.dictionaryShortToFullNames[dict]
		qwerdKey := dictionary "!!" word
		this.logEvent(3, "Seeking keyer for " qwerdKey)
		newKeyer := this.getNextKeyer(qwerdKey, qwerd, word)
		this.logEvent(2, "Setting newKeyer to " newKeyer)

		GuiControl, Text, EditKeyer, %newKeyer%
	}
	autoChord() {
        local
		Gui MainGUI:Default
		GuiControlGet qwerd, , EditQwerd

		this.logEvent(3, "Generating auto chord for " qwerd)

		; Lowercase the whole word
		StringLower, chord, qwerd
        ; Disable chording, unless the prepended q is explicitly deleted
		chord := "q" . this.map.AlphaOrder(chord)

		GuiControl, Text, EditChord, %chord%
	}

	getNextKeyer(qwerdKey, qwerd, word) {
        local
		Gui MainGUI:Default
		this.logEvent(3, "Getting next keyer for " qwerd " and " qwerdKey)
		allMatchingKeys := {}
		allMatchingKeysCount := 0

		if (qwerd = "") {
			this.logEvent(4, "Empty lazy form. Returning nill")
			Return
		}

		; Loop across all forms and keep every form that begins with this lazy key
		for loopQwerdKey in this.map.qwerds {
			loopQwerd := this.map.qwerds.item(loopQwerdKey)
			if (RegExMatch(loopQwerd.qwerd,"^" qwerd ".?$")) {
				this.logEvent(4, loopQwerd.qwerd " begins with " qwerd)
				allMatchingKeys[loopQwerdKey] := loopQwerd
			}
		}
		this.logEvent(4, "Possible matching qwerds: " allMatchingKeys.MaxIndex() "(" allMatchingKeys.Length() ")")

		; Loop across all keyers in sequence, looking for the first that's not matched
		for index, keyer in this.keyers {
			keyedQwerd := qwerd . keyer
			this.logEvent(4, "Testing keyer '" keyer "' as " keyedQwerd)
			usedKeyFound := false
			for matchingKey, matchingQwerd in allMatchingKeys {
				if (not usedKeyFound) and (matchingQwerd.qwerd = keyedQwerd) {
					; This is a match, but it might be a self-match which would be the right one to return
					this.logEvent(4, "Getting dict fullname from " matchingQwerd.dict)
					matchedQwerdKey := this.map.dictionaryShortToFullNames[matchingQwerd.dict] "!!" matchingQwerd.word
					this.logEvent(4, "Matched " keyedQwerd " as " matchedQwerdKey)
					if (word = this.map.qwerds.item(qwerd).word) {
						this.logEvent(4, "Matched keyer, qwerd, and word " this.map.qwerds.item(qwerd).word ". Returning this keyer: " keyer)
						Return keyer
					} else {
						this.logEvent(4, "Keyer " this.map.qwerds.item(qwerd).word " taken. Owned by " matchingQwerd.word)
						usedKeyFound := true
						break
					}
				} else {
					this.logEvent(4, "Not a match for " matchingQwerd.qwerd)
				}
			}
			if not usedKeyFound {
				this.logEvent(4, "Returning available keyer " keyer)
				Return keyer
			}
		}
		this.logEvent(3, "No keyer found in available options")
		Return "qq"
	}

	addValueToEditFields(WordAdd, FormAdd, QwerdAdd, ChordAdd) {
        local
		Gui MainGUI:Default
		GuiControlGet word, , EditWord
		GuiControlGet form, , EditForm
		GuiControlGet qwerd, , EditQwerd
		GuiControlGet chord, , EditChord
		GuiControlGet keyer, , EditKeyer

		Switch WordAdd
		{
		Case "s":
			word := RegExReplace(word, "y$", "ie")
		Case "es":
			word := RegExReplace(word, "e$", "")
			word := RegExReplace(word, "y$", "i")
		Case "er":
			word := RegExReplace(word, "e$", "")
		Case "ed":
			word := RegExReplace(word, "e$", "")
		Case "ing":
			word := RegExReplace(word, "e$", "")
		Case "ly":
			word := RegExReplace(word, "le$", "")
		Case "ion":
			word := RegExReplace(word, "e$", "")
		}

		; When a keyer exists, we have to remove it from the lazy form
		if (StrLen(keyer)) {
			; remove keyer from the end of the lazy form before adding LazyAdd
			qwerd := RegExReplace(qwerd, keyer "$", "")
		}

		GuiControl, Text, EditWord, %word%%WordAdd%
		GuiControl, Text, EditForm, %form%%FormAdd%
		GuiControl, Text, EditQwerd, %qwerd%%QwerdAdd%
		GuiControl, Text, EditChord, %chord%%ChordAdd%
		GuiControl, Text, EditKeyer,
	}

	prepareEdit(RowNumber) {
        local
		Gui MainGUI:Default
		this.logEvent(2, "Preparing edit for ListView from row " RowNumber)

		Gui, ListView, EditorLV
		; Get the data from the edited row
		LV_GetText(EditWord, RowNumber, 1)
		LV_GetText(EditForm, RowNumber, 2)
		LV_GetText(EditQwerd, RowNumber, 3)
		LV_GetText(EditKeyer, RowNumber, 4)
		LV_GetText(EditChord, RowNumber, 5)
		LV_GetText(EditChordable, RowNumber, 6)
		LV_GetText(EditUsage, RowNumber, 7)
		LV_GetText(EditDict, RowNumber, 8)

        ; I split this into a way to get data and a way to then fill the edit fields to enable multi-edits from one selection
        this.prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict)
	}

    prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict) {
        local
		Gui MainGUI:Default
		this.logEvent(2, "Preparing edit for ListView from data for " EditQwerd)

		; Push the data into the editing fields
		GuiControl, Text, EditWord, %EditWord%
		GuiControl, Text, EditForm, %EditForm%
		GuiControl, Text, EditQwerd, %EditQwerd%
		GuiControl, Text, EditKeyer, %EditKeyer%
		GuiControl, Text, EditChord, %EditChord%
		GuiControl, Text, EditChordable, %EditChordable%
		GuiControl, Text, EditUsage, %EditUsage%
;		GuiControlGet autoChord, , AutoGenChords
;		if (autoChord) {
;			GuiControl, Text, EditChord, Auto ; %EditChord%
;		} else {
;			GuiControl, Text, EditChord, %EditChord%
;		}

		; First convert the requested dictionary to its full name for display to the user
		EditDict := this.map.dictionaryFullToShortNames[EditDict]
		; Next change the dictionary if they're trying to edit a core dictionary
		if (InStr(EditDict, "_core.csv")) {
			supplemental_dict := RegExReplace(EditDict, "_core.csv", "_supplement.csv")
			dictList := RegexReplace(this.map.dictionaryPickList, supplemental_dict "\|?", supplemental_dict "||")
		} else {
			dictList := RegexReplace(this.map.dictionaryPickList, EditDict "\|?", EditDict "||")
		}

		GuiControl, , EditDict, %dictList%

    }

	commitEdit() {
        local
		Gui MainGUI:Default
		global DictionaryEntry
		this.logEvent(3, "Commiting edit to qwerd")

		; Grab values the user has edited and wants to commit
		GuiControlGet word, , EditWord
		GuiControlGet form, , EditForm
		GuiControlGet qwerd, , EditQwerd
		GuiControlGet keyer, , EditKeyer
		GuiControlGet chord, , EditChord
		GuiControlGet usage, , EditUsage
		GuiControlGet dictionary, , EditDict

		; Convert the dictionary from its short name to its full name for storage
		dictionary := this.map.dictionaryShortToFullNames[dictionary]

;		; Generate an autochord if it's requested by checkbox or explicit field value
;		GuiControlGet autoChord, , AutoGenChords
;		;if ( chord = "Auto" ) or ( autoChord) {
;		chord := word " = " qwerd " (" form ")  [" (StrLen(word) - StrLen(qwerd)) "]"

		newEntryCsv := word "," form "," qwerd "," keyer "," chord "," usage "," dictionary
		this.logEvent(2, "Commiting fields: " newEntryCsv)
		newEntry := new DictionaryEntry(newEntryCsv)

		this.map.propagateEntryToMaps(newEntry)

		;GuiControl, Enable, SaveDictionaries

		; Reload the search view with the new value
		this.searchMapEntries()
	}

	saveDictionaries() {
		this.logEvent(3, "Saving dictionaries")
		this.map.saveDictionaries()
        Msgbox, % "Save complete"
	}

	openPersonalizations() {
		Run, % A_Windir "\explorer.exe " this.qenv.personalDataFolder
	}

	deleteForm() {
		Gui MainGUI:Default
		; Grab values the user has edited and wants to commit
		GuiControlGet qwerdKey, , EditQwerd

		this.logEvent(3, "Deleting " qwerdKey)
		this.map.deleteQwerdFromMaps(qwerdKey)

		; Reload the search view with the new value
		this.searchForms()
	}

	updateEditsStatus(updated) {
        ; Let's try showing a count of edits
        if (updated = "Pending") {
            this.editsCount += 1
            updated := this.editsCount
        }
		this.logEvent(2, "Setting edits status to " updated)
		GuiControl, Text, EditsStatus, % "Edits: " updated

	}

	LogEvent(verbosity, message)
	{
		if (verbosity <= this.logVerbosity)
		{
			event := new LoggingEvent("editor",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
