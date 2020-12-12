#NoEnv 
#Warn 
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

logFileDE := 0
LogVerbosityDE := 2
IfNotExist, logs
    FileCreateDir, logs

logEventDE(0, "not logged")
logEventDE(1, "not verbose")
logEventDE(2, "slightly verbose")
logEventDE(3, "pretty verbose")
logEventDE(4, "very verbose")

dictionariesLoaded := 0
dictionaryListFile := "dictionary_load.list"
logEventDE(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    if (! RegexMatch(A_LoopReadLine, "^;")) {
        logEventDE(1, "Adding dictionary " A_LoopReadLine)
        dictionaries.Push(A_LoopReadLine)
    } else {
        logEventDE(1, "Skipping dictionary " A_LoopReadLine)
    }
}

negationsFile := "negations.txt"
logEventDE(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEventDE(4, "Loading negation " A_LoopReadLine)
    negations.item(A_LoopReadLine) := 1
}
            
forms := {}

LaunchEditor()

NumLines := 0
logEventDE(1, "Loading forms")
for index, dictionary in dictionaries
{
    logEventDE(1, "Loading dictionary " dictionary)
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
        logEventDE(4, "Creating form " formKey)
        if ( not forms[formKey] ) {
            ; Make sure we don't overwrite an existing word with a less used version
            forms[formKey] := form
        }
    }
    logEventDE(1, "Loaded dictionary " dictionary " resulting in " NumLines " forms")
}
logEventDE(1, "Loaded all forms")
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
    global SaveDictionaries
    global SaveProgress
    global BackupCount
    
    logEventDE(2, "Launching Editor")
    
    ; Add header text
    Gui, Add, Text, x12  y9 w700  h20 , Snazzy dictionary edits are more fun than Excel spreadsheet editing
    
    ; Add regex search fields
    Gui, Add, Edit, -WantReturn x12  y29 w160 h20 vRegexWord,  
    Gui, Add, Edit, -WantReturn x172 y29 w90  h20 vRegexFormal,  
    Gui, Add, Edit, -WantReturn x262 y29 w90  h20 vRegexLazy, 
    Gui, Add, Edit, -WantReturn x352 y29 w30  h20 vRegexKeyer, 
    Gui, Add, Edit, -WantReturn x382 y29 w60  h20 vRegexUsage,  
    Gui, Add, Edit, -WantReturn x442 y29 w160 h20 vRegexHint, 
    Gui, Add, Edit, -WantReturn x602 y29 w110 h20 vRegexDict, 
    Gui, Add, Button, Default x712 y29 w90 h20 gSearchForms, Search
    
    ; Add the data ListView
    Gui, Add, ListView, x12 y49 w700 h420 vFormsLV gFormsLV, Word|Formal|Lazy|Keyer|Usage|Hint|Dictionary
    LV_ModifyCol(5, "Integer")  ; For sorting, indicate that the Usage column is an integer.
    LV_ModifyCol(1, 160)
    LV_ModifyCol(2, 90)
    LV_ModifyCol(3, 90)
    LV_ModifyCol(4, 30)
    LV_ModifyCol(5, 60)
    LV_ModifyCol(6, 160)
    LV_ModifyCol(7, 107) ; 3 pixels short to avoid the h_scrollbar 
    
    ; Add edit fields and controls
    Gui, Add, Edit, x12  y469 w160 h20 vEditWord,  
    Gui, Add, Edit, x172 y469 w70  h20 vEditFormal,  
    Gui, Add, Button, x242 y469 w20 h20 gAutoLazyForm, L> 
    Gui, Add, Edit, x262 y469 w90  h20 vEditLazy, 
    Gui, Add, Button, x352 y469 w20 h20 gAutoKeyer, K> 
    Gui, Add, Edit, x372 y469 w30  h20 vEditKeyer, 
    Gui, Add, Edit, x402 y469 w50  h20 vEditUsage,  
    Gui, Add, Edit, x452 y469 w150 h20 vEditHint, 
    Gui, Add, Edit, x602 y469 w110 h20 vEditDict,
    Gui, Add, Button, x712 y469 w90 h20 gCommitEdit, Commit
    Gui, Add, Button, x712 y500 w90 h30 gSaveDictionaries vSaveDictionaries Disabled, Save
    Gui, Add, Progress, x12 y545 w700 h5 cOlive vSaveProgress, 1
    
    ; Add checkbox controls
    Gui, Add, CheckBox, x715 y49 w130 h20 vAutoGenHints gAutoGenHints Checked, AutoGenerate Hints
    Gui, Add, Edit, x715 y74 w20 h20 vBackupCount, 2
    Gui, Add, Text, x740 y74 w105 h20, Backups to retain 
    
    ; Generated using SmartGUI Creator 4.0
    Gui, Show, x262 y118 h560 w836, Qwertigraphy Dictionary Editor
    
    ; Create a popup menu to be used as the context menu:
    Menu, FormLVContextMenu, Add, Edit, ContextEditForm
    Menu, FormLVContextMenu, Add, Delete, ContextDeleteForm
    Menu, FormLVContextMenu, Add, Add 's', ContextAddToForm_S
    Menu, FormLVContextMenu, Add, Add 'g', ContextAddToForm_G
    Menu, FormLVContextMenu, Add, Add 'd', ContextAddToForm_D
    Menu, FormLVContextMenu, Add, Add 't', ContextAddToForm_T
    Menu, FormLVContextMenu, Add, Add 'r', ContextAddToForm_R
    Menu, FormLVContextMenu, Add, Add 'ly', ContextAddToForm_LY
    Menu, FormLVContextMenu, Default, Edit  ; Make "Edit" a bold font to indicate that double-click does the same thing.

    GuiContextMenu:  ; Launched in response to a right-click or press of the Apps key.
        if (A_GuiControl != "FormsLV")  ; Display the menu only for clicks inside the ListView.
            return
        ; Show the menu at the provided coordinates, A_GuiX and A_GuiY. These should be used
        ; because they provide correct coordinates even if the user pressed the Apps key:
        Menu, FormLVContextMenu, Show, %A_GuiX%, %A_GuiY%
    return

    GuiClose:
        logEventDE(1, "App exit called")
        ExitApp
}

FormsLV:
    logEventDE(2, "Listview event " A_GuiEvent " on " A_EventInfo)
    if (A_GuiEvent = "DoubleClick") {
        PrepareEdit(A_EventInfo)
    }
    if (A_GuiEvent = "e") {
        LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
        logEventDE(3, "Listview in-place edit to  " RowText)
        Msgbox, % "You edited row " A_EventInfo " to: " RowText
    }
    return
    
ContextEditForm:
    logEventDE(2, "Listview context edit event ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context edit event on row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    Return

ContextDeleteForm:
    logEventDE(2, "Listview context delete event ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context delete event on row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    DeleteForm()
    Return

ContextAddToForm_S:
    logEventDE(2, "Listview context add S ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add S to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("s", "-s", "s")
    CommitEdit()
    Return

ContextAddToForm_G:
    logEventDE(2, "Listview context add G ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add G to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ing", "-\-h", "g")
    CommitEdit()
    Return

ContextAddToForm_D:
    logEventDE(2, "Listview context add D ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add D to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ed", "-d", "d")
    CommitEdit()
    Return

ContextAddToForm_T:
    logEventDE(2, "Listview context add T ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add T to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ed", "-t", "t")
    CommitEdit()
    Return

ContextAddToForm_R:
    logEventDE(2, "Listview context add R ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add R to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("er", "-r", "r")
    CommitEdit()
    Return

ContextAddToForm_LY:
    logEventDE(2, "Listview context add LY ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add LY to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ly", "-e", "e")
    CommitEdit()
    Return
    
AutoLazyForm() {
    global formal
    global word
    global lazy
    GuiControlGet formal, , EditFormal
    GuiControlGet word, , EditWord
 
    ; Lowercase the whole word
    StringLower, lazy, formal

    ; Vowels
    lazy := RegexReplace(lazy, "ea", "e")
    lazy := RegexReplace(lazy, "ao", "w")
    lazy := RegexReplace(lazy, "au", "w")
    lazy := RegexReplace(lazy, "eu", "u")

    ; Consonant sets
    if (RegexMatch(word, "x")) {
        lazy := RegexReplace(lazy, "es", "x")
    }
    if (RegexMatch(word, "qu")) {
        lazy := RegexReplace(lazy, "k", "q")
    }

    ; Prefixes
    lazy := RegexReplace(lazy, "pr(e|o)", "pr")
    lazy := RegexReplace(lazy, "per", "pr")
    
    GuiControl, Text, EditLazy, %lazy%

}
    
AutoKeyer() {
    global word
    global lazy
    global keyer
    global dict
    global formKey
    GuiControlGet word, , EditWord
    GuiControlGet lazy, , EditLazy
    GuiControlGet keyer, , EditKeyer
    GuiControlGet dict, , EditDict
    formKey := dict "!!" word
    logEventDE(3, "Seeking keyer for " formKey)
    newKeyer := GetNextKeyer(formKey, lazy)
    logEventDE(2, "Setting newKeyer to " newKeyer)
    
    GuiControl, Text, EditKeyer, %newKeyer%
}

AddValueToEditFields(WordAdd, FormalAdd, LazyAdd) {

    global formal
    global word
    global lazy
    global EditWord
    global EditFormal
    global EditLazy
    GuiControlGet word, , EditWord
    GuiControlGet formal, , EditFormal
    GuiControlGet lazy, , EditLazy
    
    
    GuiControl, Text, EditWord, %EditWord%%wordAdd%
    GuiControl, Text, EditFormal, %EditFormal%%FormalAdd%
    GuiControl, Text, EditLazy, %EditLazy%%LazyAdd%
    
}

GetNextKeyer(formKey, lazy) {
    global forms
    global form
    global index
    global keyer
    global keyers := Array("","o","u","i","e","a","w","y")
    logEventDE(3, "Getting next keyer for " lazy " and " formKey)
    allMatchingKeys := {}
    allMatchingKeysCount := 0
    
    if (lazy = "") {
        logEventDE(4, "Empty lazy form. Returning nill")
        Return
    }
    for loopFormKey, form in forms {
        if (RegExMatch(form.lazy,"^" lazy)) {
            logEventDE(0, form.lazy " begins with " lazy)
            allMatchingKeys[loopFormKey] := form
            allMatchingKeysCount += 1
        }
    }
    logEventDE(4, "Possible matching forms count: " allMatchingKeysCount)
        
    for index, keyer in keyers {
        keyedLazy := lazy . keyer
        logEventDE(4, "Testing keyer " keyer " as " keyedLazy)
        usedKeyFound := false
        for matchingKey, matchingForm in allMatchingKeys {
            if (not usedKeyFound) and (matchingForm.lazy = keyedLazy) {
                logEventDE(4, "Matched " keyedLazy)
                matchedFormKey := matchingForm.dict "!!" matchingForm.word
                if matchingForm.word = forms[formKey].word {
                    logEventDE(4, "Matched keyer, lazy, and word. Returning this keyer: " keyer)
                    Return keyer
                } else {
                    logEventDE(4, "Keyer taken. Owned by " matchingForm.word)
                    usedKeyFound := true
                    break
                }
            } else {
                logEventDE(4, "Not a match for " matchingForm.lazy)
            }
        }
        if not usedKeyFound {
            logEventDE(4, "Returning available keyer " keyer)
            Return keyer
        }
    }
    logEventDE(3, "No keyer found in available options") 
    Return "qq"
}

AutoGenHints:
    logEventDE(2, "AutoHint Checkbox set to auto ")
    GuiControl, Text, EditHint, Auto 
    Return
    
DeleteForm() {
    global dictionary
    global word
    global forms
    global formKey
    
    ; Grab values the user has edited and wants to commit 
    GuiControlGet word, , EditWord
    GuiControlGet dictionary, , EditDict
    
    formKey := dictionary "!!" word
    logEventDE(3, "Deleting " formKey)
    ignore := forms.Delete(formKey)
    logEventDE(4, "Deleted " ignore.lazy)
    
    ; Reload the search view with the new value 
    SearchForms()
}
    
PrepareEdit(RowNumber) {
    logEventDE(2, "Preparing edit for ListView row " RowNumber)
    global EditDict
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    global EditUsage
    global EditHint
    
    ; Get the data from the edited row
    LV_GetText(EditWord, RowNumber, 1)
    LV_GetText(EditFormal, RowNumber, 2)
    LV_GetText(EditLazy, RowNumber, 3)
    LV_GetText(EditKeyer, RowNumber, 4)
    LV_GetText(EditUsage, RowNumber, 5)
    LV_GetText(EditHint, RowNumber, 6)
    LV_GetText(EditDict, RowNumber, 7)
    
    ; Push the data into the editing fields
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
    if (InStr(EditDict, "_core.csv")) { 
        supplemental_dict := RegExReplace(EditDict, "_core.csv", "_supplement.csv")
        GuiControl, Text, EditDict, %supplemental_dict%
    } else {
        GuiControl, Text, EditDict, %EditDict%
    }
}
CommitEdit() {
    logEventDE(3, "Commiting edit to form")
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
    form := Object("word", word, "formal", formal, "lazy", lazy, "keyer", keyer, "usage", usage, "hint", hint, "dictionary", dictionary)
    formKey := form.dictionary "!!" form.word
    
    logEventDE(2, "Commiting edit to " formKey)
    forms[formKey] := form
    
    GuiControl, Enable, SaveDictionaries
    
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
    
    global SaveProgress
    
    logEventDE(2, "Performing search of forms to populate ListView")
    logEventDE(3, "RegexWord " RegexWord ", RegexFormal " RegexFormal ", RegexLazy " RegexLazy ", RegexKeyer " RegexKeyer ", RegexUsage " RegexUsage ", RegexHint " RegexHint ", RegexDict " RegexDict )
    foundKeys := {}
    for formKey, form in forms {
        if (RegexDict) {
            if (RegExMatch(form.dictionary,RegexDict)) {
                logEventDE(4, "RegexDict matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexWord) {
            if (RegExMatch(form.word,RegexWord)) {
                logEventDE(4, "RegexWord matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexFormal) {
            if (RegExMatch(form.formal,RegexFormal)) {
                logEventDE(4, "RegexFormal matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexLazy) {
            if (RegExMatch(form.lazy,RegexLazy)) {
                logEventDE(4, "RegexLazy matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexKeyer) {
            if (RegExMatch(form.keyer,RegexKeyer)) {
                logEventDE(4, "RegexKeyer matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexUsage) {
            if (RegExMatch(form.usage,RegexUsage)) {
                logEventDE(4, "RegexUsage matched " formKey)
                foundKeys[formKey] += 1
            }
        }
        if (RegexHint) {
            if (RegExMatch(form.hint,RegexHint)) {
                logEventDE(4, "RegexHint matched " formKey)
                foundKeys[formKey] += 1
            }
        }
    }
    
    LV_Delete()
    for foundKey, count in foundKeys {
        form := forms[foundKey]
        LV_Add(, form.word, form.formal, form.lazy, form.keyer, form.usage, form.hint, form.dictionary)
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
    global SaveProgress
    global index
    global BackupCount
    
    logEventDE(1, "Saving dictionaries")
    if ( not dictionariesLoaded ) {
        logEventDE(1, "Dictionaries not yet loaded. Stopping")
        Msgbox, % "Please wait for all dictionaries to load"
        Return
    }
    
    ; Backup all dictionary files with this date stamp, unless already done 
    ; Keep 1 backup per hour
    FormatTime, bakDateStamp, , yyyyMMddHH
    for dictIndex, dictionary in dictionaries {
        bakdict := dictionary . "." . bakDateStamp . ".bak"
        logEventDE(1, "Backing up " bakdict)
        if ( not FileExist(bakdict) ) {
            ; Msgbox, % "Backing up " dictionary " to " bakdict
            FileCopy, %dictionary%, %bakdict%
        }
    }
    
    ; Removed unwanted backups
    GuiControlGet BackupCount
    for dictIndex, dictionary in dictionaries {
        logEventDE(2, "Trimming backups in " dictionary)
        FileList := ""
        Loop, Files, %dictionary%*.bak, F  ; Include Files and Directories
            FileList .= A_LoopFileTimeModified "`t" A_LoopFileName "`n"
            
        retainedCount := 0
        Sort, FileList, R ; Sort by date.
        Loop, Parse, FileList, `n
        {
            retainedCount += 1
            if (A_LoopField = "")  ; Omit the last linefeed (blank item) at the end of the list.
                continue
            StringSplit, FileItem, A_LoopField, %A_Tab%  ; Split into two parts at the tab char.
            logEventDE(2, "The next backup from " FileItem1 " is: " FileItem2)
            if (BackupCount >= retainedCount) {
                logEventDE(2, "Retaining " FileItem2)
            } else {
                logEventDE(2, "Deleting " FileItem2)
                FileDelete, %FileItem2%
            }
        }
    }
    
    ; Create a new array with sortable names by prepending the usage number 
    sortableForms := {}
    sortedCount := 0
    for word, form in forms {
        sortedCount += 1
        sortableKey :=  SubStr("0000000", StrLen(form.usage)) form.usage "_" form.word
        sortableForms[sortableKey] := form
        ; msgbox, % "created " sortableForms[sortableKey].lazy   
    }
    
    ; Open all the dictionaries for writing
    fileHandles := {}
    for index, dictionary in dictionaries
    {
        newdict := dictionary . ".new"
        fileHandle := FileOpen(newdict, "w")
        fileHandles[dictionary] := fileHandle
        header := "word,formal,lazy,keyer,usage,hint`n"
        fileHandles[dictionary].Write(header)
    }
    
    ; Loop across the sorted forms and write them 
    ; Write each to its own dictionary 
    writtenCount := 0
    GuiControl,Show, SaveProgress 
    for sortableKey, form in sortableForms {
        writtenCount += 1
        progress := Round(100*(writtenCount/sortedCount))
        GuiControl,, SaveProgress, %progress%  
        ; msgbox, % "Looping with " sortableKey "=" form.word
        line := form.word "," form.formal "," form.lazy "," form.keyer "," form.usage "," form.hint "`n"
        fileHandles[form.dictionary].Write(line)
    }
    
    ; Close all the dictionaries 
    for index, dictionary in dictionaries
    {
        fileHandles[dictionary].Close()
    }
    
    ; Overwrite the current dictionaries with the new
    for dictIndex, dictionary in dictionaries {
        logEventDE(1, "Permanently copying " newdict)
        newdict := dictionary . ".new"
        logEventDE(1, "Permanently copying " newdict " as " dictionary)
        FileCopy, %newdict%, %dictionary%, true
        FileDelete, %newdict%
    }
    
    GuiControl,Hide, SaveProgress 
    GuiControl, Disable, SaveDictionaries
}

logEventDE(verbosity, message) {
    global logFileNameDE
    global logFileDE
    global LogVerbosityDE
    if (not verbosity) or (not LogVerbosityDE)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFileDE) {
        logFileNameDE := "editor." . logDateStamp . ".log"
        logFileDE := FileOpen("logs\" logFileNameDE, "a")
        logFileDE.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= LogVerbosityDE) 
        logFileDE.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}