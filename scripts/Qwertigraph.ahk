#NoEnv 
#Warn 
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetKeyDelay, -1

logFile := 0
LogVerbosity := 4
IfNotExist, logs
    FileCreateDir, logs

logEvent(0, "not logged")
logEvent(1, "not verbose")
logEvent(2, "slightly verbose")
logEvent(3, "pretty verbose")
logEvent(4, "very verbose")

coachingLevel := 1 ; 0 is none, 1 is some, 2 is all 

dictionariesLoaded := 0
dictionaryListFile := "dictionary_load.list"
logEvent(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    logEvent(1, "Adding dictionary " A_LoopReadLine)
    dictionaries.Push(A_LoopReadLine)
}
negationsFile := "negations.txt"
logEvent(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEvent(4, "Loading negation " A_LoopReadLine)
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
    logEvent(1, "Loading dictionary " dictionary)
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
                Hotstring( ":B1C:" field3, expander.bind(field3, field1_lower, saves, power))
            }
        }

        ; Then capped cases, so they preempt all-capped cases
        if not negations.item(field3_capped) {
            try {
                Hotstring( ":B1C:" field3_capped )
                duplicateLazyOutlineCount += 1
                duplicateLazyOutlines := duplicateLazyOutlines . "," field3_capped
            } catch {
                Hotstring( ":B1C:" field3_capped, expander.bind(field3_capped, field1_capped, saves, power))
            }
        }
        try {
            ; Try the "word" as a hotstring to see whether it exists
            Hotstring( ":B0:" field1 )
        } catch {
            ; The "word" does not exist, so use it as a coaching hint
            Hotstring( ":B0:" field1, hinter.bind(field1, field3, field6, saves, power))
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
                Hotstring( ":B1C:" field3_upper, expander.bind(field3_upper, field1_upper, saves, power))
            }
        }
        
        progress := Round(100 * (NumLines/expectedForms))
        GuiControl, , LoadProgress, %progress%
        ; if ( NumLines > 800 ) {
        ;     break
        ; }
    }
    logEvent(1, "Loaded dictionary " dictionary " resulting in " NumLines " forms")
}
GuiControl, Hide, LoadProgress
logEvent(1, "Loaded all forms")

if FileExist("duplicateLazyOutlines.txt")
    FileDelete, duplicateLazyOutlines.txt

logEvent(1, duplicateLazyOutlineCount " duplicate outlines: " duplicateLazyOutlines)
FileAppend duplicateLazyOutlineCount%duplicateLazyOutlineCount% , duplicateLazyOutlines.txt
FileAppend %duplicateLazyOutlines%, duplicateLazyOutlines.txt

; Doing this include earlier kills the script, but it loads immediately even though it's last
#Include personal.ahk

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



ExpandOutline(lazy, word, saves, power) {
    global phraseEndings
    global lastExpandedForm
    global lastExpandedWord
    global lastEndChar
    global TypedCharacters
    global DisplayedCharacters
    
    logEvent(3, "Expanding " lazy " into " word " saving " saves " at power " power)
    if (lastEndChar = "'") {
        logEvent(4, "lastEndChar is '")
        ; Don't allow contractions to expand the ending
        send, % SubStr(A_ThisHotkey, 6) . A_EndChar
    } else if (A_EndChar = "!") {
        logEvent(4, "lastEndChar is !")
        ; Exclam is the ALT character
        send, % word 
        send {!}
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)
    } else {
        logEvent(4, "Handling normally")
        send, % word A_EndChar
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)
    }
    UpdateDashboard()
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
    Gui,Add,Button,x5 y5 h20 w70 gSaveOpportunities,Save log
    Gui,Add,Button,x80 y5 h20 w70 gClearOpportunities,Clear log
    Gui,Add,Text,vDashboardText x5 w150 r5, Characters saved in typing
    Gui,Add,Text,vAcruedTipText w200 h500, Shorthand Coach
    Gui,Add,Text,vActiveTipText r1 w200, Last word not shortened
    Gui,Add, Progress, h5 cOlive vLoadProgress, 1
    Gui,Add,Picture, w70 h-1 x170 y5, coach.png
    Gui,Show,w250 h656 x%vWidth% y%vHeight%, Shorthand Coach
}

UpdateDashboard() {
    global TypedCharacters
    global DisplayedCharacters
    global MissedCharacters
    SavedCharacters := DisplayedCharacters - TypedCharacters
    Efficiency := Round(SavedCharacters / DisplayedCharacters, 2)
    Learning := Round(SavedCharacters / MissedCharacters, 2)
    
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
CoachOutline(word, outline, hint, saves, power) {
    global coachingLevel
    AddOpportunity(hint,saves)
    if (coachingLevel > 1) {
        FlashHint(hint)
    } else if (coachingLevel = 1) {
        if (power > 1.5) {
            FlashHint(hint)
        }
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
    GuiControl,,AcruedTipText, % ListOpportunities(Opportunities)
}

OfferRetry() {
    global forms
    global lastExpandedWord
    global lastExpandedForm
    global index
    global keyers := Array("","o","u","i","e","a","w","y")
    
    logEvent(1, "Offering retry with " lastExpandedWord "/" lastExpandedForm)
    possibles := {}
    possiblesCount := 0
    possiblesMsg := "Did you mean: `n"
    for index, keyer in keyers {
        keyedLazy := lastExpandedForm . keyer
        StringLower, keyedLazy, keyedLazy
        logEvent(3, "Testing availability of  " keyedLazy)
        if (forms[keyedLazy]) {
            possibles[keyedLazy] := forms[keyedLazy]
            possiblesCount += 1
            possiblesMsg := possiblesMsg keyedLazy ": " forms[keyedLazy] "`n"
            logEvent(3, "Available:  " keyedLazy " as " forms[keyedLazy])
        } else {
            logEvent(3, "Not available:  " keyedLazy)
        }
    }
    Msgbox, % possiblesMsg
}

ExitLogging() {
    SaveOpportunities()
    LogEvent(1, "Application exited")
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

LogEvent(verbosity, message) {
    global logFileName
    global logFile
    global logVerbosity
    if (not verbosity) or (not logVerbosity)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFile) {
        logFileName := "qwertigraph." . logDateStamp . ".log"
        logFile := FileOpen("logs\" logFileName, "a")
        logFile.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= logVerbosity) 
        logFile.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}