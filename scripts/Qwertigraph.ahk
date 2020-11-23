#NoEnv 
#Warn 
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetKeyDelay, -1
nibY := -999 ; disable GreggPad until loaded. 

retrains := { "w":1, "nd":1 }

logFileQG := 0
logVerbosityQG := 4
IfNotExist, logs
    FileCreateDir, logs

logEventQG(0, "not logged")
logEventQG(1, "not verbose")
logEventQG(2, "slightly verbose")
logEventQG(3, "pretty verbose")
logEventQG(4, "very verbose")

coachingLevel := 1 ; 0 is none, 1 is some, 2 is all 

dictionariesLoaded := 0
dictionaryListFile := "dictionary_load.list"
logEventQG(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    if (! RegexMatch(A_LoopReadLine, "^;")) {
        logEventQG(1, "Adding dictionary " A_LoopReadLine)
        dictionaries.Push(A_LoopReadLine)
    } else {
        logEventQG(1, "Skipping dictionary " A_LoopReadLine)
    }
}

negationsFile := "negations.txt"
logEventQG(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEventQG(4, "Loading negation " A_LoopReadLine)
    negations.item(A_LoopReadLine) := 1
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
        forms[field3] := field1
        
        ; Add case sensitive hotstrings for lower case, capped case, and all caps case
        saves := StrLen(field1) - StrLen(field3)
        power := StrLen(field1) / StrLen(field3)

        ; lowered hotstring
        StringLower, field1_lower, field1
        StringUpper, field1_upper, field1
        StringUpper, field3_upper, field3
        field1_capped := SubStr(field1_upper, 1, 1) . SubStr(field1, 2, (StrLen(field1) - 1))
        field3_capped := SubStr(field3_upper, 1, 1) . SubStr(field3, 2, (StrLen(field3) - 1))
        
        ; First lowered cases
        if not negations.item(field3) {
            try {
                Hotstring( ":B1C:" field3 )
                duplicateLazyOutlineCount += 1
                duplicateLazyOutlines := duplicateLazyOutlines . "," field3
            } catch {
                Hotstring( ":B1C:" field3, expander.bind(field3, field1_lower, field2, saves, power))
            }
        }

        ; Then capped cases, so they preempt all-capped cases
        if not negations.item(field3_capped) {
            try {
                Hotstring( ":B1C:" field3_capped )
                duplicateLazyOutlineCount += 1
                duplicateLazyOutlines := duplicateLazyOutlines . "," field3_capped
            } catch {
                Hotstring( ":B1C:" field3_capped, expander.bind(field3_capped, field1_capped, field2, saves, power))
            }
        }
        try {
            ; Try the "word" as a hotstring to see whether it exists
            Hotstring( ":B0:" field1 )
        } catch {
            ; The "word" does not exist, so use it as a coaching hint
            if (StrLen(field1) < 40) {
                Hotstring( ":B0:" field1, hinter.bind(field1, field3, field6, field2, saves, power))
            }
        }

        ; finally allcapped cases or HE will preempt He for E
        if not negations.item(field3_upper) {
            try {
                Hotstring( ":B1C:" field3_upper )
                if StrLen(field3_upper) > 1 {
                    ; Don't record every single character lazy outline as a dupe
                    duplicateLazyOutlineCount += 1
                    duplicateLazyOutlines := duplicateLazyOutlines . "," field3_upper
                }
            } catch {
                Hotstring( ":B1C:" field3_upper, expander.bind(field3_upper, field1_upper, field2, saves, power))
            }
        }
        
        progress := Round(100 * (NumLines/expectedForms))
        Gui Qwertigraph:Default
        GuiControl, , LoadProgress, %progress%
        ; if ( NumLines > 800 ) {
        ;     break
        ; }
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
; Load personal.ahk only after all other code has run
; And before loading any Qwertigraphy native briefs
; But ignore if it doesn't exist
#Include *i personal.ahk

return 

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
    OfferRetry()
    Return



ExpandOutline(lazy, word, formal, saves, power) {
    global phraseEndings
    global lastExpandedForm
    global lastExpandedWord
    global lastEndChar
    global TypedCharacters
    global DisplayedCharacters
    global nibY
    global retrains
    
    if (retrains.HasKey(lazy)) {
        Msgbox, % "Oops: " lazy
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
        ; VisualizeForm(formal, "blue")
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
    Gui,Qwertigraph:Add,Picture, w70 h-1 x170 y5, coach.png
    Gui,Qwertigraph:Show,w250 h656 x%vWidth% y%vHeight%, Shorthand Coach
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
    global coachingLevel
    global nibY
    AddOpportunity(hint,saves)
    if (coachingLevel > 1) {
        FlashHint(hint)
    } else if (coachingLevel = 1) {
        if (power > 1.5) {
            FlashHint(hint)
        }
    }
    if (nibY > -1) {
        ; VisualizeForm(formal, "red")
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

OfferRetry() {
    global forms
    global lastExpandedWord
    global lastExpandedForm
    global index
    global keyers := Array("","o","u","i","e","a","w","y")
    
    logEventQG(1, "Offering retry with " lastExpandedWord "/" lastExpandedForm)
    possibles := {}
    possiblesCount := 0
    possiblesMsg := "Did you mean: `n"
    for index, keyer in keyers {
        keyedLazy := lastExpandedForm . keyer
        StringLower, keyedLazy, keyedLazy
        logEventQG(3, "Testing availability of  " keyedLazy)
        if (forms[keyedLazy]) {
            possibles[keyedLazy] := forms[keyedLazy]
            possiblesCount += 1
            possiblesMsg := possiblesMsg keyedLazy ": " forms[keyedLazy] "`n"
            logEventQG(3, "Available:  " keyedLazy " as " forms[keyedLazy])
        } else {
            logEventQG(3, "Not available:  " keyedLazy)
        }
    }
    Msgbox, % possiblesMsg
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