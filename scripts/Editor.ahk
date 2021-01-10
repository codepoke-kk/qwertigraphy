#NoEnv 
#Warn 
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

if (A_ScriptName == "Editor.ahk") {
    Editing := True
    FreeStandingEditor := True
} else {
    FreeStandingEditor := False
}

logFileDE := 0
LogVerbosityDE := 4
IfNotExist, logs
    FileCreateDir, logs

logEventDE(0, "not logged")
logEventDE(1, "not verbose")
logEventDE(2, "slightly verbose")
logEventDE(3, "pretty verbose")
logEventDE(4, "very verbose")

PersonalDataFolder := A_AppData "\Qwertigraph"
logEventDE(1, "Personal data found at " PersonalDataFolder)

dictionariesLoaded := 0
dictionaryListFile := PersonalDataFolder "\dictionary_load.list"
dictionaryDropDown := ""
dictionaryFullToShortNames := {}
dictionaryShortToFullNames := {}
logEventDE(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    if (! RegexMatch(A_LoopReadLine, "^;")) {
        logEventDE(1, "Adding dictionary " A_LoopReadLine)
        personalizedDict := RegExReplace(A_LoopReadLine, "AppData", PersonalDataFolder) 
        dictionaries.Push(personalizedDict)
        dictShortName := RegExReplace(personalizedDict, "^(.*\\)", "")
        dictionaryFullToShortNames[personalizedDict] := dictShortName
        dictionaryDropDown := dictionaryDropDown "|" dictShortName 
        logEventDE(1, "Adding dictionary names " dictShortName " for " personalizedDict)
        dictionaryShortToFullNames[dictShortName] := personalizedDict
    } else {
        logEventDE(1, "Skipping dictionary " A_LoopReadLine)
    }
}

negationsFile := PersonalDataFolder "\negations.txt"
logEventDE(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEventDE(4, "Loading negation " A_LoopReadLine)
    negations.item(A_LoopReadLine) := 1
}
            
forms := {}

if (Editing) {
    ShowEditor()
}

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

return

ShowEditor() {
    local
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
    global dictionaryDropDown
    global SaveProgress
    global BackupCount
    global Editing
    global FreeStandingEditor
    
    logEventDE(2, "Launching Editor")
    
    Gui Editor:Default
    ; Add header text
    Gui, Editor:Add, Text, x12  y9 w700  h20 , Snazzy dictionary edits are more fun than Excel spreadsheet editing
    
    ; Add regex search fields
    Gui, Editor:Add, Edit, -WantReturn x12  y29 w160 h20 vRegexWord,  
    Gui, Editor:Add, Edit, -WantReturn x172 y29 w90  h20 vRegexFormal,  
    Gui, Editor:Add, Edit, -WantReturn x262 y29 w90  h20 vRegexLazy, 
    Gui, Editor:Add, Edit, -WantReturn x352 y29 w30  h20 vRegexKeyer, 
    Gui, Editor:Add, Edit, -WantReturn x382 y29 w60  h20 vRegexUsage,  
    Gui, Editor:Add, Edit, -WantReturn x442 y29 w160 h20 vRegexHint, 
    Gui, Editor:Add, Edit, -WantReturn x602 y29 w210 h20 vRegexDict, 
    Gui, Editor:Add, Button, Default x812 y29 w90 h20 gSearchForms, Search
    
    ; Add the data ListView
    Gui, Editor:Add, ListView, x12 y49 w800 h420 vFormsLV gFormsLV, Word|Formal|Lazy|Keyer|Usage|Hint|Dictionary
    LV_ModifyCol(5, "Integer")  ; For sorting, indicate that the Usage column is an integer.
    LV_ModifyCol(1, 160)
    LV_ModifyCol(2, 90)
    LV_ModifyCol(3, 90)
    LV_ModifyCol(4, 30)
    LV_ModifyCol(5, 60)
    LV_ModifyCol(6, 160)
    LV_ModifyCol(7, 207) ; 3 pixels short to avoid the h_scrollbar 
    
    ; Add edit fields and controls
    Gui, Editor:Add, Edit, x12  y469 w160 h20 vEditWord,  
    Gui, Editor:Add, Edit, x172 y469 w70  h20 vEditFormal,  
    Gui, Editor:Add, Button, x242 y469 w20 h20 gAutoLazyForm, L> 
    Gui, Editor:Add, Edit, x262 y469 w90  h20 vEditLazy, 
    Gui, Editor:Add, Button, x352 y469 w20 h20 gAutoKeyer, K> 
    Gui, Editor:Add, Edit, x372 y469 w30  h20 vEditKeyer, 
    Gui, Editor:Add, Edit, x402 y469 w50  h20 vEditUsage,  
    Gui, Editor:Add, Edit, x452 y469 w150 h20 vEditHint, 
    Gui, Editor:Add, DropDownList, x602 y469 w210 r5 vEditDict, %dictionaryDropDown%
    Gui, Editor:Add, Button, x812 y469 w90 h20 gCommitEdit, Commit
    Gui, Editor:Add, Button, x812 y500 w90 h30 gSaveDictionaries vSaveDictionaries Disabled, Save
    Gui, Editor:Add, Progress, x12 y545 w700 h5 cOlive vSaveProgress, 1
    
    ; Add checkbox controls
    Gui, Editor:Add, CheckBox, x815 y49 w130 h20 vAutoGenHints gAutoGenHints Checked, AutoGenerate Hints
    Gui, Editor:Add, Button, x812 y444 w90 h20 gOpenPersonalizations, Personalizations
    Gui, Editor:Add, Edit, x815 y74 w20 h20 vBackupCount, 2
    Gui, Editor:Add, Text, x840 y74 w105 h20, Backups to retain 
    
    ; Create a popup menu to be used as the context menu:
    Menu, FormsLVContextMenu, Add, Edit, ContextEditForm
    Menu, FormsLVContextMenu, Add, Delete, ContextDeleteForm
    Menu, FormsLVContextMenu, Add, Add 's', ContextAddToForm_S
    Menu, FormsLVContextMenu, Add, Add 'g', ContextAddToForm_G
    Menu, FormsLVContextMenu, Add, Add 'd', ContextAddToForm_D
    Menu, FormsLVContextMenu, Add, Add 't', ContextAddToForm_T
    Menu, FormsLVContextMenu, Add, Add 'r', ContextAddToForm_R
    Menu, FormsLVContextMenu, Add, Add 'ly', ContextAddToForm_LY
    Menu, FormsLVContextMenu, Default, Edit  ; Make "Edit" a bold font to indicate that double-click does the same thing.
    
    ; Generated using SmartGUI Creator 4.0
    Gui, Show, x262 y118 h560 w936, Qwertigraphy Dictionary Editor
}

EditorGuiContextMenu: ; Launched in response to a right-click or press of the Apps key.
    Gui Editor:Default
    if (A_GuiControl != "FormsLV")  ; Display the menu only for clicks inside the ListView.
        return
    ; Show the menu at the provided coordinates, A_GuiX and A_GuiY. These should be used
    ; because they provide correct coordinates even if the user pressed the Apps key:
    Menu, FormsLVContextMenu, Show, %A_GuiX%, %A_GuiY%
    return

FormsLV:
    Gui Editor:Default
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
    Gui Editor:Default
    logEventDE(2, "Listview context edit event ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context edit event on row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    return

ContextDeleteForm:
    Gui Editor:Default
    logEventDE(2, "Listview context delete event ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context delete event on row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    DeleteForm()
    return

ContextAddToForm_S:
    Gui Editor:Default
    logEventDE(2, "Listview context add S ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add S to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("s", "-s", "s")
    CommitEdit()
    return

ContextAddToForm_G:
    Gui Editor:Default
    logEventDE(2, "Listview context add G ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add G to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ing", "-\-h", "g")
    CommitEdit()
    return

ContextAddToForm_D:
    Gui Editor:Default
    logEventDE(2, "Listview context add D ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add D to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ed", "-d", "d")
    CommitEdit()
    return

ContextAddToForm_T:
    Gui Editor:Default
    logEventDE(2, "Listview context add T ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add T to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ed", "-t", "t")
    CommitEdit()
    return

ContextAddToForm_R:
    Gui Editor:Default
    logEventDE(2, "Listview context add R ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add R to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("er", "-r", "r")
    CommitEdit()
    return

ContextAddToForm_LY:
    Gui Editor:Default
    logEventDE(2, "Listview context add LY ")
    FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
    if not FocusedRowNumber  ; No row is focused.
        return
    logEventDE(3, "Listview context add LY to row " FocusedRowNumber)
    PrepareEdit(FocusedRowNumber)
    AddValueToEditFields("ly", "-e", "e")
    CommitEdit()
    return
    
AutoGenHints:
    logEventDE(2, "AutoHint Checkbox set to auto ")
    GuiControl, Text, EditHint, Auto 
    return
    
EditorGuiClose:
    LogEventDE(1, "App exit called")
    if (FreeStandingEditor) {
        ExitApp
    } else {
        Editing := false
        Gui Editor:Default
        Gui Destroy
        Gui Qwertigraph:Default
        GuiControl, , EditingCheckbox, 0
    }
   
AutoLazyForm() {
    local
    Gui Editor:Default
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
    local
    global dictionaryShortToFullNames
    
    Gui Editor:Default
    GuiControlGet word, , EditWord
    GuiControlGet lazy, , EditLazy
    GuiControlGet keyer, , EditKeyer
    GuiControlGet dict, , EditDict
    
    dictionary := dictionaryShortToFullNames[dict]
    formKey := dictionary "!!" word
    logEventDE(3, "Seeking keyer for " formKey)
    newKeyer := GetNextKeyer(formKey, lazy)
    logEventDE(2, "Setting newKeyer to " newKeyer)
    
    GuiControl, Text, EditKeyer, %newKeyer%
}

AddValueToEditFields(WordAdd, FormalAdd, LazyAdd) {
    local
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    Gui Editor:Default
    GuiControlGet word, , EditWord
    GuiControlGet formal, , EditFormal
    GuiControlGet lazy, , EditLazy
    GuiControlGet keyer, , EditKeyer
    
    ; I'm not ready to build a full grammar here, but removing "e" is going to save time 
    if (InStr("er|ed|ing", WordAdd)) {
        ; remove "e" from the end of the word when adding er, ed, or ing
        word := RegExReplace(word, "e$", "")
    }
    
    ; When a keyer exists, we have to remove it from the lazy form
    if (StrLen(keyer)) {
        ; remove keyer from the end of the lazy form before adding LazyAdd
        lazy := RegExReplace(lazy, keyer "$", "")
    }
    
    GuiControl, Text, EditWord, %word%%WordAdd%
    GuiControl, Text, EditFormal, %formal%%FormalAdd%
    GuiControl, Text, EditLazy, %lazy%%LazyAdd%
    GuiControl, Text, EditKeyer, 
    
}

GetNextKeyer(formKey, lazy) {
    local
    global forms
    global dictionaryShortToFullNames
    keyers := Array("","o","u","i","e","a","w","y")
    logEventDE(3, "Getting next keyer for " lazy " and " formKey)
    allMatchingKeys := {}
    allMatchingKeysCount := 0
    
    if (lazy = "") {
        logEventDE(4, "Empty lazy form. Returning nill")
        Return
    }
    
    ; Loop across all forms and keep every form that begins with this lazy key
    for loopFormKey, form in forms {
        if (RegExMatch(form.lazy,"^" lazy)) {
            logEventDE(0, form.lazy " begins with " lazy)
            allMatchingKeys[loopFormKey] := form
            allMatchingKeysCount += 1
        }
    }
    logEventDE(4, "Possible matching forms count: " allMatchingKeysCount)
        
    ; Loop across all keyers in sequence, looking for the first that's not matched
    for index, keyer in keyers {
        keyedLazy := lazy . keyer
        logEventDE(4, "Testing keyer " keyer " as " keyedLazy)
        usedKeyFound := false
        for matchingKey, matchingForm in allMatchingKeys {
            if (not usedKeyFound) and (matchingForm.lazy = keyedLazy) {
                ; This is a match, but it might be a self-match which would be the right one to return
                matchedFormKey := dictionaryShortToFullNames[matchingForm.dict] "!!" matchingForm.word
                logEventDE(4, "Matched " keyedLazy " as " matchedFormKey)
                if matchingForm.word = forms[formKey].word {
                    logEventDE(4, "Matched keyer, lazy, and word " forms[formKey].word ". Returning this keyer: " keyer)
                    Return keyer
                } else {
                    logEventDE(4, "Keyer " forms[formKey].word " taken. Owned by " matchingForm.word)
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
    
DeleteForm() {
    local
    global forms
    global dictionaryShortToFullNames
    
    Gui Editor:Default
    ; Grab values the user has edited and wants to commit 
    GuiControlGet word, , EditWord
    GuiControlGet dictionary, , EditDict
    
    ; Convert the dictionary from its short name to its full name for storage
    dictionary := dictionaryShortToFullNames[dictionary]
    
    formKey := dictionary "!!" word
    logEventDE(3, "Deleting " formKey)
    ignore := forms.Delete(formKey)
    logEventDE(4, "Deleted " ignore.lazy)
    
    ; Reload the search view with the new value 
    SearchForms()
}
    
PrepareEdit(RowNumber) {
    local
    logEventDE(2, "Preparing edit for ListView row " RowNumber)
    global EditDict
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    global EditUsage
    global EditHint
    global EditForm
    global dictionaryDropDown
    global dictionaryFullToShortNames
    
    Gui Editor:Default    
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
    
    ; First convert the requested dictionary to its full name for display to the user
    EditDict := dictionaryFullToShortNames[EditDict]
    ; Next change the dictionary if they're trying to edit a core dictionary 
    if (InStr(EditDict, "_core.csv")) { 
        supplemental_dict := RegExReplace(EditDict, "_core.csv", "_supplement.csv")
        dictList := RegexReplace(dictionaryDropDown, supplemental_dict "\|?", supplemental_dict "||")
    } else {
        dictList := RegexReplace(dictionaryDropDown, EditDict "\|?", EditDict "||")
    }
    
    GuiControl, , EditDict, %dictList%
}
CommitEdit() {
    local
    global EditDict
    global EditWord
    global EditFormal
    global EditLazy
    global EditKeyer
    global EditUsage
    global EditHint
    global EditForm
    global forms
    global FreeStandingEditor
    global dictionaryShortToFullNames
    logEventDE(3, "Commiting edit to form")
    
    Gui Editor:Default
    ; Grab values the user has edited and wants to commit 
    GuiControlGet formal, , EditFormal
    GuiControlGet word, , EditWord
    GuiControlGet lazy, , EditLazy
    GuiControlGet keyer, , EditKeyer
    GuiControlGet usage, , EditUsage
    GuiControlGet hint, , EditHint
    GuiControlGet dictionary, , EditDict
    
    ; Convert the dictionary from its short name to its full name for storage
    dictionary := dictionaryShortToFullNames[dictionary]
    
    ; Generate an autohint if it's requested by checkbox or explicit field value 
    GuiControlGet autoHint, , AutoGenHints
    if ( hint = "Auto" ) or ( autoHint) {
        hint := word " = " lazy " (" formal ")  [" (StrLen(word) - StrLen(lazy)) "]" 
    }
    
    ; Build the form and key then commit it to the in-memory dictionary 
    form := Object("word", word, "formal", formal, "lazy", lazy, "keyer", keyer, "usage", usage, "hint", hint, "dictionary", dictionary)
    formKey := form.dictionary "!!" form.word
    
    logEventDE(2, "Commiting edit to " formKey)    
    logEventDE(3, "Commiting fields: word," word " formal," formal " lazy," lazy " keyer," keyer " usage," usage " hint," hint " dictionary," dictionary)
    forms[formKey] := form
    
    if (! FreeStandingEditor) {
        CreateFormsFromDictionary(word, formal, lazy, hint, true)
    }
    GuiControl, Enable, SaveDictionaries
    
    ; Reload the search view with the new value 
    SearchForms()
}

SearchForms() {
    local
    global RegexDict
    global RegexWord
    global RegexFormal
    global RegexLazy
    global RegexKeyer
    global RegexUsage
    global RegexHint
    global forms
    Gui Editor:Default
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
    local
    global dictionariesLoaded 
    global dictionaries
    global dictionary
    global sortableKey
    global sortableWords
    global forms 
    global progress
    global SaveProgress
    global BackupCount
    global PersonalDataFolder
    
    Gui Editor:Default
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
                FileDelete, %PersonalDataFolder%\%FileItem2%
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
OpenPersonalizations() {
    global PersonalDataFolder
    Run, % A_Windir "\explorer.exe " PersonalDataFolder
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