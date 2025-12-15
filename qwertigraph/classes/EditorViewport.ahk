
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
; Add auto-edit buttons
Gui, Add, Button, x838 y90 w90 h20 gEditorOpenPersonalizations, Personalizations
Gui, Add, Button, x838 y130 w90 h20 gEditorEditRow, Edit
Gui, Add, Button, x838 y150 w90 h20 gEditorDeleteRow, Delete
Gui, Add, Button, x838 y170 w90 h20 gEditorCreateRow_S, Add S
Gui, Add, Button, x838 y190 w90 h20 gEditorCreateRow_D, Add D
Gui, Add, Button, x838 y210 w90 h20 gEditorCreateRow_G, Add G
Gui, Add, Button, x838 y230 w90 h20 gEditorCreateRow_T, Add T
Gui, Add, Button, x838 y250 w90 h20 gEditorCreateRow_R, Add R
Gui, Add, Button, x838 y270 w90 h20 gEditorCreateRow_LY, Add LY
Gui, Add, Button, x838 y290 w90 h20 gEditorCreateRow_ALLY, Add ALLY
Gui, Add, Button, x838 y310 w90 h20 gEditorCreateRow_ION, Add ION
Gui, Add, Button, x838 y330 w90 h20 gEditorCreateRow_ATION, Add ATION
Gui, Add, Button, x838 y350 w90 h20 gEditorCreateRow_ABLE, Add ABLE
Gui, Add, Button, x838 y370 w90 h20 gEditorCreateRow_ABILITY, Add ABILITY
Gui, Add, Button, x838 y390 w90 h20 gEditorCreateRow_ES, Add ES
Gui, Add, Button, x838 y410 w90 h20 gEditorCreateRow_SDG, Add S+D+G
Gui, Add, Button, x838 y430 w90 h20 gEditorCreateRow_ESDG, Add ES+D+G

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
    editor.AutoKey()
    editor.AutoChord()
    GuiControl, Focus, EditDict
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
EditorCreateRow_ALLY() {
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
    editor.addValueToEditFields("ally", "-e", "e", "e")
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
EditorCreateRow_ATION() {
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
    editor.addValueToEditFields("ation", "-sh", "z", "z")
    editor.autoChord()
    editor.commitEdit()
    editor.SearchMapEntries()
}
EditorCreateRow_ABLE() {
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
    editor.addValueToEditFields("able", "-b", "b", "b")
    editor.autoChord()
    editor.commitEdit()
    editor.SearchMapEntries()
}
EditorCreateRow_ABILITY() {
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
    editor.addValueToEditFields("ability", "-\-b", "bo", "bo")
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
EditorCreateRow_ESDG() {
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

    editor.logEvent(3, "Listview context edit event adding ES+D+G on row " FocusedRowNumber)
    editor.prepareEditFromData(EditWord, EditForm, EditQwerd, EditKeyer, EditChord, EditChordable, EditUsage, EditDict)
    editor.addValueToEditFields("es", "-s", "s", "s")
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
    keyers := Array("o","u","i")
    counters := Array("","1","2","3","4","5","6","7","8","9")

    __New(map,engine)
    {
        this.map := map
        this.engine := engine 
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

        this.logEvent(2, "Starting this.map.qwerds count before looping search for matching words is " this.map.qwerds.count)
        failureCount := 0
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
            try {
                this.logEvent(4, "loopQwerdKey is " loopQwerdKey)
                qwerd := this.map.qwerds.item(loopQwerdKey)
                this.logEvent(4, "found qwerd " qwerd.qwerd)
            } catch e {
                this.logEvent(2, "loopQwerdKey " loopQwerdKey " failed")
                failureCount += 1
                continue 
            }
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
        this.logEvent(2, "Ending this.map.qwerds count after looping search for matching words is " this.map.qwerds.count)
        
        if (failureCount) {
            Msgbox, % "Failed to load " failureCount " words. Check Editor logs"
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

        this.logEvent(2, "Generating auto qwerd for " form)

        ; Lowercase the whole word
        StringLower, qwerd, form

        for uniform_pattern_index, uniform_pattern in this.qenv.uniform_patterns {
            this.logEvent(4, "Testing " word "," qwerd " against  " uniform_pattern.word_pattern "," uniform_pattern.form_pattern)
            if ((RegExMatch(word, uniform_pattern.word_pattern)) and (RegExMatch(qwerd, uniform_pattern.form_pattern))) {
                this.logEvent(1, "Matched pattern " word "," qwerd " against  " uniform_pattern.word_pattern "," uniform_pattern.form_pattern)
                qwerd := RegExReplace(qwerd, uniform_pattern.form_pattern, uniform_pattern.replacement_pattern)
                this.logEvent(1, "New qwerd is " qwerd " because " uniform_pattern.comment)
            }
        }

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

        GuiControl, Text, EditQwerd, % qwerd . newKeyer
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
        this.logEvent(1, "Getting next keyer for " qwerd " and " qwerdKey)
        allMatchingKeys := {}
        allMatchingKeysCount := 0

        if (qwerd = "") {
            this.logEvent(4, "Empty lazy form. Returning nill")
            Return
        }
        
        ; Drop out and return null if no keyer is needed 
        if ((!this.map.qwerds.exists(qwerd)) or (word = this.map.qwerds.item(qwerd).word)) {
            this.logEvent(1, "Natural qwerd " qwerd " does not exist or already is word " word ". No keyer necessary")
            return ""
        }
        
        ; We must have a keyer for this qwerd, so loop and present up to 3 options
        ; I will return a candidate, which may be the null candidate, so predefine it as null
        return_candidate := {"qwerd":"","word":"","keyer":""}
        ; Make up to 30 keyers possible by following each of the 3 with a digit
        counter_loop: 
        for counter_index, counter in this.counters {
            candidates := []
            ; As of this writing, there are 3 keyers so we will present 4 options to the user
            keyer_loop: 
            for keyer_index, keyer in this.keyers {
                keyed_qwerd := qwerd . keyer . counter
                this.logEvent(1, "Testing keyer '" counter keyer "' as " keyed_qwerd)
                ; Present either a matching word or the fact a keyer is available 
                if (this.map.qwerds.exists(keyed_qwerd)) {
                    candidate := {"qwerd":keyed_qwerd,"word":this.map.qwerds.item(keyed_qwerd).word,"keyer":keyer . counter}
                } else {
                    candidate := {"qwerd":keyed_qwerd,"word":"-available-","keyer":keyer . counter}
                }
                candidates.Push(candidate)
            }
            ; Add an option to reject keying any of these three options and go to the next set
            candidate := {"qwerd":"","word":"Next options","keyer":"nn"}
            candidates.Push(candidate)
            prompt := "Key in your selected keyer from this list or you can key in any keyer you choose. Your choice will displace any existing word.`n"
            prompt := prompt qwerd " = " this.map.qwerds.item(qwerd).word "`n"
            for candidate_index, candidate in candidates {
                prompt := prompt "(" candidate.keyer ") " candidate.qwerd " = " candidate.word "`n"
            }
            ; We have to stop the engine to make text input without expansion possible
            this.engine.Stop()
            InputBox, selection, % "Choose Keyer", % prompt,,300,300,
            this.engine.Start()
            if ErrorLevel {
                this.logEvent(1, "User cancelled keyer selection")
                break counter_loop
            } else {
                this.logEvent(1, "User chose keyer " selection)
                if (selection = "nn") {
                    this.logEvent(1, "User wants the next set of options")
                } else {
                    return_candidate.keyer := selection
                    break counter_loop
                }
            }
        }
        return return_candidate.keyer
        
    
;        $newentry_keyer = ''
;        # Disambiguate if the qwerd already exists or is in the block as qwerds list
;        if (($uniform_entries.ContainsKey("$($new_entry.qwerd)")) -or ($block_as_qwerds.ContainsKey($new_entry.qwerd))) {
;            :CounterLoop foreach ($counter in $uniform_counters) {
;                :KeyerLoop foreach ($keyer in $uniform_keyers) {
;                    $newentry_keyer = "$keyer$counter"
;                    if ((-not $uniform_entries.ContainsKey("$($new_entry.qwerd)$newentry_keyer")) -and (-not $block_as_qwerds.ContainsKey("$($new_entry.qwerd)$newentry_keyer"))) {
;                        Break CounterLoop
;                    }
;                }
;            }
;        }
;        $qwerd = "$($new_entry.qwerd)$newentry_keyer"

;        ; Loop across all forms and keep every form that could be a keyed qwerd
;        for loopQwerdKey in this.map.qwerds {
;            loopQwerd := this.map.qwerds.item(loopQwerdKey)
;            if (RegExMatch(loopQwerd.qwerd,"^" qwerd "[oiu]?[0-9]?$")) {
;                this.logEvent(1, loopQwerd.qwerd " begins with " qwerd)
;                allMatchingKeys[loopQwerdKey] := loopQwerd
;            }
;        }
;        this.logEvent(1, "Possible matching qwerds: " allMatchingKeys.MaxIndex() "(" allMatchingKeys.Length() ")")
;
;        ;;; I wrote this to look at keyers in every dictionary, whether active or not 
;        ;;; I don't understand why that was important, so I am going to keep this code 
;        ;;; But I'm going to replace it with lighter code 
;        ; Loop across all keyers in sequence, looking for the first that's not matched
;        ; The first keyer is null, so the plain qwerd will match if it's available 
;        for index, keyer in this.keyers {
;            keyedQwerd := qwerd . keyer
;            this.logEvent(4, "Testing keyer '" keyer "' as " keyedQwerd)
;            ; Track whether I've found an already used key 
;            usedKeyFound := false
;            ; Loop with our candidate keyedQwerd across only everything that might be a matching key 
;            for matchingKey, matchingQwerd in allMatchingKeys {
;                if (not usedKeyFound) and (matchingQwerd.qwerd = keyedQwerd) {
;                    ; This is a match, but it might be a self-match which would be the right one to return
;                    this.logEvent(4, "Getting dict fullname from " matchingQwerd.dict)
;                    matchedQwerdKey := this.map.dictionaryShortToFullNames[matchingQwerd.dict] "!!" matchingQwerd.word
;                    this.logEvent(4, "Matched " keyedQwerd " as " matchedQwerdKey)
;                    ; Prechecking key exists before all lookups, since the hash is expanding somewhere 
;                    if (this.map.qwerds.exists(qwerd)) {
;                        if (word = this.map.qwerds.item(qwerd).word) {
;                            ; This is a self-match, so let it through 
;                            this.logEvent(4, "Matched keyer, qwerd, and word " this.map.qwerds.item(qwerd).word ". Returning this keyer: " keyer)
;                            Return keyer
;                        } else {
;                            this.logEvent(4, "Keyer " this.map.qwerds.item(qwerd).word " taken. Owned by " matchingQwerd.word)
;                            usedKeyFound := true
;                            break
;                        }
;                    } else {
;                        this.logEvent(1, "Defensively found " qwerd " does not exist in keyer search. Maybe should not happen?")
;                    }
;                } else {
;                    this.logEvent(4, "Not a match for " matchingQwerd.qwerd)
;                }
;            }
;            if not usedKeyFound {
;                this.logEvent(4, "Returning available keyer " keyer)
;                Return keyer
;            }
;        }
;        this.logEvent(3, "No keyer found in available options")
;        Return "qq"
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
            word := RegExReplace(word, "y$", "i")
        Case "ing":
            word := RegExReplace(word, "e$", "")
        Case "ly":
            word := RegExReplace(word, "le$", "")
        Case "ion":
            word := RegExReplace(word, "e$", "")
        Case "ation":
            word := RegExReplace(word, "e$", "")
        }
        
        Switch FormAdd
        {
        Case "-sh":
            form := RegExReplace(form, "-t$", "")
        }
        
        Switch QwerdAdd
        {
        Case "z":
            qwerd := RegExReplace(qwerd, "t$", "")
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
;       GuiControlGet autoChord, , AutoGenChords
;       if (autoChord) {
;           GuiControl, Text, EditChord, Auto ; %EditChord%
;       } else {
;           GuiControl, Text, EditChord, %EditChord%
;       }

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
        
        ; Protect displaced entries by changing their qwerds for later retrieval and correction
        if ((this.map.qwerds.exists(qwerd)) and (this.map.qwerds.item(qwerd).word != word)) {
            displaced := this.map.qwerds.item(qwerd)
            displaced.qwerd := displaced.qwerd . "qk"
            this.map.propagateEntryToMaps(displaced)
        }

        ; Convert the dictionary from its short name to its full name for storage
        dictionary := this.map.dictionaryShortToFullNames[dictionary]

        newEntryCsv := word "," form "," qwerd "," keyer "," chord "," usage "," dictionary
        this.logEvent(2, "Commiting fields: " newEntryCsv)
        newEntry := new DictionaryEntry(newEntryCsv)

        this.map.propagateEntryToMaps(newEntry)

        ; Reload the search view with the new value
        this.searchMapEntries()
    }

    saveDictionaries() {
        this.logEvent(3, "Saving dictionaries")
        this.map.saveDictionaries()
        ; Msgbox, % "Save complete"
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
