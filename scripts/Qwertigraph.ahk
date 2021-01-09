#NoEnv 
#Warn 
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetKeyDelay, -1
nibY := -999 ; disable GreggPad until loaded. 

; Make the pretty icon
I_Icon = coach.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%
;return

; Prepare to do the logging
logFileQG := 0
logVerbosityQG := 4
IfNotExist, logs
    FileCreateDir, logs

logEventQG(0, "not logged")
logEventQG(1, "not verbose")
logEventQG(2, "slightly verbose")
logEventQG(3, "pretty verbose")
logEventQG(4, "very verbose")

; It can coach more or less
coachingLevel := 1 ; 0 is none, 1 is some, 2 is all 

; Include files needed to create a release
FileInstall, dictionaries\anniversary_core.csv, dictionaries\anniversary_core.csv, true
FileInstall, dictionaries\anniversary_supplement.csv, dictionaries\anniversary_supplement.csv, true
FileInstall, dictionaries\anniversary_phrases.csv, dictionaries\anniversary_phrases.csv, true
FileInstall, dictionaries\anniversary_modern.csv, dictionaries\anniversary_modern.csv, true
FileInstall, dictionaries\anniversary_cmu.csv, dictionaries\anniversary_cmu.csv, true
FileInstall, templates\dictionary_load.template, templates\dictionary_load.template, true
FileInstall, templates\negations.template, templates\negations.template, true
FileInstall, templates\personal.template, templates\personal.template, true
FileInstall, templates\retrains.template, templates\retrains.template, true
FileInstall, coach.ico, coach.ico, true


; Personalize this user's data
PersonalDataFolder := A_AppData "\Qwertigraph"
logEventQG(1, "Personal data found at " PersonalDataFolder)
IfNotExist, %PersonalDataFolder% 
{
    FileCreateDir, %PersonalDataFolder%
    logEventQG(1, "Created " PersonalDataFolder)
}
personalizedFiles := {"templates\personal.template":"personal.csv", "templates\dictionary_load.template":"dictionary_load.list", "templates\negations.template":"negations.txt", "templates\retrains.template":"retrains.txt"}
for fileKey, fileValue in personalizedFiles
{
    IfNotExist, %PersonalDataFolder%\%fileValue%
    {
        FileCopy, %fileKey%, %PersonalDataFolder%\%fileValue%, false
        logEventQG(1, "Created " PersonalDataFolder "\" fileValue)
    }
}

; Finally, down to business 
dictionariesLoaded := 0
dictionaryListFile := PersonalDataFolder "\dictionary_load.list"
logEventQG(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    if (! RegexMatch(A_LoopReadLine, "^;")) {
        logEventQG(1, "Adding dictionary " A_LoopReadLine)
        personalizedDict := RegExReplace(A_LoopReadLine, "AppData", PersonalDataFolder) 
        dictionaries.Push(personalizedDict)
    } else {
        logEventQG(1, "Skipping dictionary " A_LoopReadLine)
    }
}

negationsFile := PersonalDataFolder "\negations.txt"
logEventQG(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEventQG(4, "Loading negation " A_LoopReadLine)
    negations.item(A_LoopReadLine) := 1
}
retrainsFile := PersonalDataFolder "\retrains.txt"
logEventQG(1, "Loading retrains from " retrainsFile)
retrains := {}
Loop,Read,%retrainsFile%   ;read retrains
{
    logEventQG(4, "Loading retrain " A_LoopReadLine)
    retrains[A_LoopReadLine] := 1
}
            
words := CSobj()
hints := CSobj()
expander := func("ExpandOutline")
hinter := func("CoachOutline")

hasNotLaunchedCoach := 1
wordsExpanded := 0
charsSaved := 0
lastExpandedWord := ""
lastExpandedForm := ""
lastEndChar := ""
forms := {}
expansions := ""
phraseEndings := {}
TypedCharacters := 0
DisplayedCharacters := 0
MissedCharacters := 0
expectedForms := 40000
NumLines := 0
Coaching := true
Retraining := true
Gregging := true
Qwerting := true
Editing := false

LaunchCoach()

duplicateLazyOutlines := ""
duplicateLazyOutlineCount := 0

for index, dictionary in dictionaries
{
    logEventQG(1, "Loading dictionary " dictionary)
    Loop,Read,%dictionary%   ;read dictionary into HotStrings
    {
        Global NumLines
        NumLines:=A_Index-1
        IfEqual, A_Index, 1, Continue ; Skip title row
        Loop,Parse,A_LoopReadLine,CSV   ;parse line into 6 fields
        {
            ; msgbox % "Making field" A_Index " = " A_LoopField
            field%A_Index% = %A_LoopField%
        }
        
        CreateFormsFromDictionary(field1, field2, field3, field6, False)
        
        progress := Round(100 * (NumLines/expectedForms))
        Gui Qwertigraph:Default
        GuiControl, , LoadProgress, %progress%
    }
    logEventQG(1, "Loaded dictionary " dictionary " resulting in " NumLines " forms")
}
Gui Qwertigraph:Default
GuiControl, Hide, LoadProgress
logEventQG(1, "Loaded all forms")

if FileExist("duplicateLazyOutlines.txt")
    FileDelete, duplicateLazyOutlines.txt

logEventQG(1, duplicateLazyOutlineCount " duplicate outlines: " duplicateLazyOutlines)
FileAppend duplicateLazyOutlineCount%duplicateLazyOutlineCount% , duplicateLazyOutlines.txt
FileAppend %duplicateLazyOutlines%, duplicateLazyOutlines.txt



#Include GreggPad.ahk
#Include Editor.ahk
; Load personal.ahk only after all other code has run
; And before loading any Qwertigraphy native briefs
; But ignore if it doesn't exist
#Include *i personal.ahk


; Allow manual contracting
:?*:'s::'s 
:?*:'d::'d
:?*:'t::'t
:?*:'m::'m
:?*:'re::'re
:?*:'ve::'ve
:?*:'ll::'ll
; Allow "hypenateds-"
:?*:non-::non-
:?*:meta-::meta-
:?*:pre-::pre-
:?*:re-::re-
:?*:-c::-c
:?*:-d::-d
:?*:-t::-t
:?*:-q::-q
:?*:-p::-p
:?*:-m::-m
:?*:`:q::`:q

:*:htpp::http://
:*:htps::https://

:C:AHK::AHK
::ahk::AutoHotkey

; Enable/Disable
^j::
	Suspend toggle
    Return

; Enable expansion to work immediately after control-backspace
~^Backspace::
    hotstring("reset")
    Return
    
; Enable expansion and strip the "control" from the stroke on punctuation
^Space::
    hotstring("reset")
    Send {Space}
    Return
^.::
    hotstring("reset")
    Send {.}
    Return
^,::
    hotstring("reset")
    Send {,}
    Return
^-::
    hotstring("reset")
    Send {-}
    Return
+^;::
    hotstring("reset")
    Send {:}
    Return
^Tab::
    hotstring("reset")
    Send {Tab}
    Return
^Enter::
    hotstring("reset")
    Send {Enter}
    Return
    
; Show related strokes after an expansion
#^r::
    hotstring("reset")
    RecordOpportunity()
    Return
; Show related strokes after an expansion
#^e::
    hotstring("reset")
    OfferEdit()
    Return

CreateFormsFromDictionary(word, formal, lazy, hint, overwrite) {
    local
    global forms
    global negations
    global duplicateLazyOutlineCount
    global duplicateLazyOutlines
    global expander
    global hinter
    global progress
    global LoadProgress
    global expectedForms

    forms[lazy] := word
    
    ; Add case sensitive hotstrings for lower case, capped case, and all caps case
    saves := StrLen(word) - StrLen(lazy)
    power := StrLen(word) / StrLen(lazy)

    ; variously cased hotstrings
    StringLower, word_lower, word
    StringUpper, word_upper, word
    StringUpper, lazy_upper, lazy
    word_capped := SubStr(word_upper, 1, 1) . SubStr(word, 2, (StrLen(word) - 1))
    lazy_capped := SubStr(lazy_upper, 1, 1) . SubStr(lazy, 2, (StrLen(lazy) - 1))
    
    if (overwrite) {
        ; On dynamic adds, force every add to happen 
        ; Add the hinter entry first, so it will be overwritten by a lazy form if they happen to be the same 
        Hotstring( ":B0:" word, hinter.bind(word, lazy, hint, formal, saves, power))
        Hotstring( ":B1C:" lazy, expander.bind(lazy, word_lower, formal, saves, power))
        Hotstring( ":B1C:" lazy_capped, expander.bind(lazy_capped, word_capped, formal, saves, power))
        Hotstring( ":B1C:" lazy_upper, expander.bind(lazy_upper, word_upper, formal, saves, power))
    } else {
        ; We're not overwriting on initial load, so test whether a form already exists before adding it
        ; This allows the personal dictionary to take priority over the core dictionary so people can do their own thing 
        ; First lowered cases
        if not negations.item(lazy) {
            try {
                Hotstring( ":B1C:" lazy )
                duplicateLazyOutlineCount += 1
                duplicateLazyOutlines := duplicateLazyOutlines . "," lazy
            } catch {
                Hotstring( ":B1C:" lazy, expander.bind(lazy, word_lower, formal, saves, power))
            }
        }

        ; Then capped cases, so they preempt all-capped cases
        if not negations.item(lazy_capped) {
            try {
                Hotstring( ":B1C:" lazy_capped )
                duplicateLazyOutlineCount += 1
                duplicateLazyOutlines := duplicateLazyOutlines . "," lazy_capped
            } catch {
                Hotstring( ":B1C:" lazy_capped, expander.bind(lazy_capped, word_capped, formal, saves, power))
            }
        }
        try {
            ; Try the "word" as a hotstring to see whether it exists
            Hotstring( ":B0:" word )
        } catch {
            ; The "word" does not exist, so use it as a coaching hint
            if (StrLen(word) < 40) {
                Hotstring( ":B0:" word, hinter.bind(word, lazy, hint, formal, saves, power))
            }
        }

        ; finally allcapped cases or HE will preempt He for E
        if not negations.item(lazy_upper) {
            try {
                Hotstring( ":B1C:" lazy_upper )
                if StrLen(lazy_upper) > 1 {
                    ; Don't record every single character lazy outline as a dupe
                    duplicateLazyOutlineCount += 1
                    duplicateLazyOutlines := duplicateLazyOutlines . "," lazy_upper
                }
            } catch {
                Hotstring( ":B1C:" lazy_upper, expander.bind(lazy_upper, word_upper, formal, saves, power))
            }
        }
    }
}

ExpandOutline(lazy, word, formal, saves, power) {
    global phraseEndings
    global lastExpandedForm
    global lastExpandedWord
    global lastEndChar
    global TypedCharacters
    global DisplayedCharacters
    global nibY
    global Retraining
    global retrains
    
    if (Retraining) {
        if (retrains.HasKey(lazy)) {
            Msgbox, % "Oops: " lazy
        }
    }
    logEventQG(3, "Expanding " lazy " into " word " saving " saves " at power " power)
    if (lastEndChar = "'") {
        logEventQG(4, "lastEndChar is '")
        ; Don't allow contractions to expand the ending
        send, % SubStr(A_ThisHotkey, 6) . A_EndChar
    } else if (A_EndChar = "!") {
        logEventQG(4, "lastEndChar is !")
        ; Exclam is the ALT character
        send, % word 
        send {!}
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)
    } else {
        logEventQG(4, "Handling normally")
        send, % word A_EndChar
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)
    }
    UpdateDashboard()
    if (nibY > -1) {
        VisualizeForm(lazy, formal, "blue")
    }
    lastExpandedWord := word
    lastExpandedForm := lazy
    lastEndChar := A_EndChar
    hotstring("reset")
}

FlashHint(hint) {
    Tooltip %hint%, A_CaretX, A_CaretY + 30
    SetTimer, ClearToolTip, -1500
    return 

    ClearToolTip:
      ToolTip
    return 
}


LaunchCoach() {
    global MissedText
    global DashboardText
    global AcruedTipText
    global ActiveTipText
    global Opportunities
    global LoadProgress
    global Coaching
    global Retraining
    global Gregging
    global Greggingcheckbox
    global Qwerting
    global Editing
    global Editingcheckbox
    ; Define here so each launch refreshes the list
    Opportunities := {}
    
    SysGet, vWidth, 59
    SysGet, vHeight, 60
    
    vWidth := vWidth - 445
    vHeight := vHeight - 1110

    Gui, +AlwaysOnTop +Resize
    Gui,Qwertigraph:Add,Button,x5 y5 h20 w70 gSaveOpportunities,Save log
    Gui,Qwertigraph:Add,Button,x80 y5 h20 w70 gClearOpportunities,Clear log
    Gui,Qwertigraph:Add,Text,vDashboardText x5 w150 r5, Characters saved in typing
    Gui,Qwertigraph:Add,Text,vAcruedTipText w200 h500, Shorthand Coach
    Gui,Qwertigraph:Add,Text,vActiveTipText r1 w200, Last word not shortened
    Gui,Qwertigraph:Add, Progress, h5 cOlive vLoadProgress, 1
    Gui,Qwertigraph:Add,Checkbox,x170 y5 h20 w70 gCoachingSub Checked,Coach
    Gui,Qwertigraph:Add,Checkbox,x170 y25 h20 w70 gRetrainingSub Checked,Retrain
    Gui,Qwertigraph:Add,Checkbox,x170 y45 h20 w70 vGreggingCheckbox gGreggingSub Checked,Gregg
    Gui,Qwertigraph:Add,Checkbox,x175 y65 h20 w70 gQwertingSub Checked,Qwerthand
    Gui,Qwertigraph:Add,Checkbox,x170 y85 h20 w70 vEditingCheckbox gEditingSub,Edit
    Gui,Qwertigraph:Show,w250 h656 x%vWidth% y%vHeight%, Shorthand Coach
}

; OK. I know a checkbox should set a variable and I should not have to do this. I could not make it work. 
CoachingSub() {
    global Coaching 
    Coaching := (! Coaching)
    ; Msgbox, % "Coach " Coaching
}
RetrainingSub() {
    global Retraining 
    Retraining := (! Retraining)
    ; Msgbox, % "Retrain " Retraining
}
GreggingSub() {
    global Gregging 
    if (Gregging) {
        Gregging := false
        Gui GreggPad:Default
        Gui Destroy
    } else {
        Gregging := True 
        ShowGreggPad()
    }
    ; Msgbox, % "Gregg " Gregging
}
QwertingSub() {
    global Qwerting 
    Qwerting := (! Qwerting)
    ; Msgbox, % "Qwert " Qwerting
}
EditingSub() {
    global Editing 
    if (Editing) {
        Editing := false
        Gui Editor:Default
        Gui Destroy
    } else {
        Editing := true
        ShowEditor()
    }
}

UpdateDashboard() {
    global TypedCharacters
    global DisplayedCharacters
    global MissedCharacters
    SavedCharacters := DisplayedCharacters - TypedCharacters
    Efficiency := Round(SavedCharacters / DisplayedCharacters, 2)
    Learning := Round(SavedCharacters / MissedCharacters, 2)
    
    Gui Qwertigraph:Default
    GuiControl,,DashboardText, % "Typed:" TypedCharacters "`nSaved:" SavedCharacters "`nMissed: " MissedCharacters "`nEfficiency:" Efficiency "`nLearning:" Learning
}
RecordOpportunity() {
    clipboard := ""  ; Start off empty to allow ClipWait to detect when the text has arrived.
    Send ^c
    ClipWait  ; Wait for the clipboard to contain text.
    AddOpportunity(clipboard " (recorded)", 7)
    FlashHint(clipboard " (recorded)")
}
AddOpportunity(tip,saves) {
    global coachingLevel
    if (! coachingLevel ) {
        Return
    }
    
    if ( saves < 1 and coachingLevel = 1 ) { 
        ; Don't record opportunities that save nothing or less than nothing
        Return
    }
    global Opportunities
    global MissedCharacters
    MissedCharacters := MissedCharacters + saves
    if ( ! Opportunities[tip] ) {
        Opportunities[tip] := saves
    } else {
        Opportunities[tip] := Opportunities[tip] + saves
    }
    ; MsgBox, % "Seeing " tip " for the " Opportunities[tip]
    Gui Qwertigraph:Default
    GuiControl,,AcruedTipText, % ListOpportunities(Opportunities)
    GuiControl,,ActiveTipText, %tip%
    UpdateDashboard()
}
ListOpportunities(opps) {
  summaries := ""
  for summary,count in opps {
    summaries .= SubStr("000", StrLen(count)) count ": " summary "`n"
  }
  Sort, summaries, R
  return Trim(summaries, "`n")
}
CoachOutline(word, outline, hint, formal, saves, power) {
    global Coaching
    global coachingLevel
    global nibY
    
    if (! Coaching) {
        Return
    }
        
    AddOpportunity(hint,saves)
    if (coachingLevel > 1) {
        FlashHint(hint)
    } else if (coachingLevel = 1) {
        if (power > 1.5) {
            FlashHint(hint)
        }
    }
    if (nibY > -1) {
        VisualizeForm(outline, formal, "red")
    }
}
; Provided by Josh Grams
SaveOpportunities()
{
	Global Opportunities
	FileDelete, opportunities.txt
	FileAppend, % ListOpportunities(Opportunities), opportunities.txt
}

; Provided by Josh Grams
ClearOpportunities()
{
	Global Opportunities
	Opportunities := {}
    Gui Qwertigraph:Default
    GuiControl,,AcruedTipText, % ListOpportunities(Opportunities)
}

OfferEdit() {
    global Editing
    global RegexWord
    global RegexLazy
    
    clipboard := ""  ; Start off empty to allow ClipWait to detect when the text has arrived.
    Send ^c
    ClipWait  ; Wait for the clipboard to contain text.

    logEventQG(1, "Offering edit with " Clipboard)
    
    if (! Editing) {
        Gui Qwertigraph:Default
        GuiControl, , EditingCheckbox, 1
        EditingSub()
    }
    
    trimmed := Trim(Clipboard)
    StringLower, lowered, trimmed
    
    Gui Editor:Default
    GuiControl, Text, RegexWord, ^%lowered%
    GuiControl, Text, RegexLazy, ^%lowered%.?$
    Gui Show
    SearchForms()
}

ExitLogging() {
    SaveOpportunities()
    logEventQG(1, "Application exited")
}



CSobj() {
    static base := object("_NewEnum","__NewEnum", "Next","__Next", "__Set","__Setter", "__Get","__Getter")
    return, object("__sd_obj__", ComObjCreate("Scripting.Dictionary"), "base", base)
}
    __Getter(self, key) {
        return, self.__sd_obj__.item(key)
    }
    __Setter(self, key, value) {
        self.__sd_obj__.item(key) := value
        return, false
    }
    __NewEnum(self) {
        return, self
    }
    __Next(self, ByRef key = "", ByRef val = "") {
        static Enum
        if not Enum
            Enum := self.__sd_obj__._NewEnum
        if Not Enum[key], val:=self[key]
            return, Enum:=false
        return, true
    }

logEventQG(verbosity, message) {
    global logFileNameQG
    global logFileQG
    global logVerbosityQG
    if (not verbosity) or (not logVerbosityQG)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFileQG) {
        logFileNameQG := "qwertigraph." . logDateStamp . ".log"
        logFileQG := FileOpen("logs\" logFileNameQG, "a")
        logFileQG.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= logVerbosityQG) 
        logFileQG.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}
