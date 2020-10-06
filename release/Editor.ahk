#NoEnv 
#Warn 
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

dictionariesLoaded := 0
dictionaryListFile := "dictionary_load.list"
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    dictionaries.Push(A_LoopReadLine)
}

negationsFile := "negations.txt"
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    negations.item(A_LoopReadLine) := 1
}
            
forms := {}

LaunchEditor()

NumLines := 0
for index, dictionary in dictionaries
{
    Loop,Read,%dictionary%   ;read dictionary into array
    {
        NumLines:=A_Index-1
        IfEqual, A_Index, 1, Continue ; Skip title row
        Loop,Parse,A_LoopReadLine,CSV   ;parse line into 6 fields
        {
            field%A_Index% = %A_LoopField%
        }
        
        form := Object("dictionary", dictionary, "word", field1, "formal", field2, "lazy", field3, "keyer", field4, "usage", field5, "hint", field6)

        formKey := form.dictionary "!!" form.word
        if ( not forms[formKey] ) {
            ; Make sure we don't overwrite an existing word with a less used version
            forms[formKey] := form
        }
        
        ; if ( NumLines > 800 ) {
        ;     break
        ; }
    }
}
dictionariesLoaded := 1

;Msgbox, % "I have forms " sortableWords["00000005_password"]
return 


LaunchEditor() {
    global Forms
    global EditorTitle
    global FormsLV
    global RegexDict
    global RegexWord
    global RegexFormal
    global RegexLazy
    global RegexKeyer
    global RegexUsage
    global RegexHint
    global EditDict
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    global EditUsage
    global EditHint
    global EditForm
    global AutoGenHints
    
    ; Add header text
    Gui, Add, Text, x12  y9 w90  h20 , Formal
    Gui, Add, Text, x102 y9 w160 h20 , Word
    Gui, Add, Text, x262 y9 w90  h20 , Lazy
    Gui, Add, Text, x352 y9 w30  h20 , Keyer
    Gui, Add, Text, x382 y9 w60  h20 , Usage
    Gui, Add, Text, x442 y9 w160 h20 , Hint
    Gui, Add, Text, x602 y9 w110 h20 , Dictionary
    
    ; Add regex search fields
    Gui, Add, Edit, -WantReturn x12  y29 w90  h20 vRegexFormal,  
    Gui, Add, Edit, -WantReturn x102 y29 w160 h20 vRegexWord,  
    Gui, Add, Edit, -WantReturn x262 y29 w90  h20 vRegexLazy, 
    Gui, Add, Edit, -WantReturn x352 y29 w30  h20 vRegexKeyer, 
    Gui, Add, Edit, -WantReturn x382 y29 w60  h20 vRegexUsage,  
    Gui, Add, Edit, -WantReturn x442 y29 w160 h20 vRegexHint, 
    Gui, Add, Edit, -WantReturn x602 y29 w110 h20 vRegexDict, 
    Gui, Add, Button, Default x712 y29 w90 h20 gSearchForms, Search
    
    ; Add the data ListView
    Gui, Add, ListView, x12 y49 w700 h420 vFormsLV gFormsLV -ReadOnly, Formal|Word|Lazy|Keyer|Usage|Hint|Dictionary
    LV_ModifyCol(5, "Integer")  ; For sorting, indicate that the Usage column is an integer.
    LV_ModifyCol(1, 90)
    LV_ModifyCol(2, 160)
    LV_ModifyCol(3, 90)
    LV_ModifyCol(4, 30)
    LV_ModifyCol(5, 60)
    LV_ModifyCol(6, 160)
    LV_ModifyCol(7, 107) ; 3 pixels short to avoid the h_scrollbar 
    
    ; Add edit fields and controls
    Gui, Add, Edit, x12  y469 w90  h20 vEditFormal,  
    Gui, Add, Edit, x102 y469 w160 h20 vEditWord,  
    Gui, Add, Edit, x262 y469 w90  h20 vEditLazy, 
    Gui, Add, Edit, x352 y469 w30  h20 vEditKeyer, 
    Gui, Add, Edit, x382 y469 w60  h20 vEditUsage,  
    Gui, Add, Edit, x442 y469 w160 h20 vEditHint, 
    Gui, Add, Edit, x602 y469 w110 h20 vEditDict, 
    Gui, Add, Button, x712 y469 w90 h20 gCommitEdit, Commit
    Gui, Add, Button, x582 y500 w130 h30 gSaveDictionaries, Save
    
    ; Add checkbox controls
    Gui, Add, CheckBox, x715 y49 w130 h20 vAutoGenHints gAutoGenHints, AutoGenerate Hints
    
    ; Generated using SmartGUI Creator 4.0
    Gui, Show, x262 y118 h551 w836, New GUI Window
    
    ; Create a popup menu to be used as the context menu:
    Menu, FormLVContextMenu, Add, Edit, ContextEditForm
    Menu, FormLVContextMenu, Add, Delete, ContextDeleteForm
    Menu, FormLVContextMenu, Default, Edit  ; Make "Edit" a bold font to indicate that double-click does the same thing.

    GuiContextMenu:  ; Launched in response to a right-click or press of the Apps key.
        if (A_GuiControl != "FormsLV")  ; Display the menu only for clicks inside the ListView.
            return
        ; Show the menu at the provided coordinates, A_GuiX and A_GuiY. These should be used
        ; because they provide correct coordinates even if the user pressed the Apps key:
        Menu, FormLVContextMenu, Show, %A_GuiX%, %A_GuiY%
    return

    GuiClose:
        ExitApp
}

FormsLV:
    if (A_GuiEvent = "DoubleClick") {
        PrepareEdit(A_EventInfo)
    }
    if (A_GuiEvent = "e") {
        LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
        Msgbox, % "You edited row " A_EventInfo " to: " RowText
    }
    return
    
ContextEditForm:
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    PrepareEdit(FocusedRowNumber)
    Return

ContextDeleteForm:
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    Msgbox, % "Delete " FocusedRowNumber
    Return
    
AutoGenHints:
    GuiControl, Text, EditHint, Auto 
    Return
    
PrepareEdit(RowNumber) {
    global EditDict
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    global EditUsage
    global EditHint
    
    ; Get the data from the edited row
    LV_GetText(EditFormal, RowNumber, 1)
    LV_GetText(EditWord, RowNumber, 2)
    LV_GetText(EditLazy, RowNumber, 3)
    LV_GetText(EditKeyer, RowNumber, 4)
    LV_GetText(EditUsage, RowNumber, 5)
    LV_GetText(EditHint, RowNumber, 6)
    LV_GetText(EditDict, RowNumber, 7)
    
    ; Push the data into the editing fields
    GuiControl, Text, EditDict, %EditDict%
    GuiControl, Text, EditWord, %EditWord%
    GuiControl, Text, EditFormal, %EditFormal%
    GuiControl, Text, EditLazy, %EditLazy%
    GuiControl, Text, EditKeyer, %EditKeyer%
    GuiControl, Text, EditUsage, %EditUsage%
    GuiControlGet autoHint, , AutoGenHints
    if (autoHint) {
        GuiControl, Text, EditHint, Auto ; %EditHint%
    } else {
        GuiControl, Text, EditHint, %EditHint%
    }
}
CommitEdit() {
    global dictionary
    global word
    global formal
    global lazy
    global keyer
    global usage
    global hint
    global forms
    global form
    global formKey
    
    ; Grab values the user has edited and wants to commit 
    GuiControlGet formal, , EditFormal
    GuiControlGet word, , EditWord
    GuiControlGet lazy, , EditLazy
    GuiControlGet keyer, , EditKeyer
    GuiControlGet usage, , EditUsage
    GuiControlGet hint, , EditHint
    GuiControlGet dictionary, , EditDict
    
    ; Generate an autohint if it's requested by checkbox or explicit field value 
    GuiControlGet autoHint, , AutoGenHints
    if ( hint = "Auto" ) or ( autoHint) {
        hint := word " = " lazy " (" formal ")  [" (StrLen(word) - StrLen(lazy)) "]" 
    }
    
    ; Build the form and key then commit it to the in-memory dictionary 
    form := Object("dictionary", dictionary, "word", word, "formal", formal, "lazy", lazy, "keyer", keyer, "usage", usage, "hint", hint)
    formKey := form.dictionary "!!" form.word
    forms[formKey] := form
    
    ; Reload the search view with the new value 
    SearchForms()
}

SearchForms() {
    global RegexDict
    global RegexWord
    global RegexFormal
    global RegexLazy
    global RegexKeyer
    global RegexUsage
    global RegexHint
    global word
    global forms
    global form
    global formKey
    GuiControlGet RegexDict
    GuiControlGet RegexWord
    GuiControlGet RegexFormal
    GuiControlGet RegexLazy
    GuiControlGet RegexKeyer
    GuiControlGet RegexUsage
    GuiControlGet RegexHint
    
    foundKeys := {}
    for formKey, form in forms {
        if (RegexDict) {
            if (RegExMatch(form.dictionary,RegexDict)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexWord) {
            if (RegExMatch(form.word,RegexWord)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexFormal) {
            if (RegExMatch(form.formal,RegexFormal)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexLazy) {
            if (RegExMatch(form.lazy,RegexLazy)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexKeyer) {
            if (RegExMatch(form.keyer,RegexKeyer)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexUsage) {
            if (RegExMatch(form.usage,RegexUsage)) {
                foundKeys[formKey] += 1
            }
        }
        if (RegexHint) {
            if (RegExMatch(form.hint,RegexHint)) {
                foundKeys[formKey] += 1
            }
        }
    }
    
    LV_Delete()
    for foundKey, count in foundKeys {
        form := forms[foundKey]
        LV_Add(, form.formal, form.word, form.lazy, form.keyer, form.usage, form.hint, form.dictionary)
        ;Msgbox, % "Found " foundKey
    }
}

SaveDictionaries() {
    global dictionariesLoaded 
    global dictionaries
    global dictionary
    global sortableKey
    global sortableWords
    global forms 
    global form 
    global word 
    
    if ( not dictionariesLoaded ) {
        Msgbox, % "Please wait for all dictionaries to load"
        Return
    }
    
    ; Backup all dictionary files with this date stamp, unless already done 
    ; Keep 1 backup per hour
    FormatTime, bakDateStamp, , yyyyMMddHH
    for dictIndex, dictionary in dictionaries {
        bakdict := dictionary . "." . bakDateStamp . ".bak"
        ; msgbox, % "Creating " bakdict
        if ( not FileExist(bakdict) ) {
            ; Msgbox, % "Backing up " dictionary " to " bakdict
            FileCopy, %dictionary%, %bakdict%
        }
    }
    
    ; Refresh all dictionary files with .new versions
    for dictIndex, dictionary in dictionaries {
        newdict := dictionary . ".new"
        ; msgbox, % "Creating " newdict
        FileDelete, %newdict%
        FileAppend, word`,formal`,lazy`,keyer`,usage`,hint`n, %newdict%
    }
    
    ; Create a new array with sortable names by prepending the usage number 
    sortableForms := {}
    for word, form in forms {
        sortableKey :=  SubStr("0000000", StrLen(form.usage)) form.usage "_" form.word
        sortableForms[sortableKey] := form
        ; msgbox, % "created " sortableForms[sortableKey].lazy   
    }
    
    ; Loop across the sorted forms and write them 
    ; Write each to its own dictionary 
    for sortableKey, form in sortableForms {
        ; msgbox, % "Looping with " sortableKey "=" form.word
        line := form.word "," form.formal "," form.lazy "," form.keyer "," form.usage "," form.hint "`n"
        newdict := form.dictionary . ".new"
        FileAppend, %line%, %newdict%
    }
    
    ; Overwrite the current dictionaries with the new
    for dictIndex, dictionary in dictionaries {
        newdict := dictionary . ".new"
        Msgbox, % "Copying " newdict " over " dictionary
        FileCopy, %newdict%, %dictionary%, true
        FileDelete, %newdict%
    }
}