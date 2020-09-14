#NoEnv 
#Warn 
; #Hotstring NoMouse  ; Allowing the mouse because clicks reset the hotstring
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetKeyDelay, -1

dictionaries := []
dictionaries.Push("personal.csv")
dictionaries.Push("phrases.csv")
dictionaries.Push("outlines_final.csv")
negations_file := "negations.csv"
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negations_file%   ;read negations
{
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
lastEndChar := ""
expansions := ""
phraseEndings := {}
TypedCharacters := 0
DisplayedCharacters := 0
MissedCharacters := 0

LaunchCoach()

for index, dictionary in dictionaries
{
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
        
        ; Add case sensitive hotstrings for lower case, capped case, and all caps case
        saves := StrLen(field1) - StrLen(field3)
        power := StrLen(field1) / StrLen(field3)

        ; lowered hotstring
        StringLower, field1_lower, field1
        if not negations.item(field3)
            Hotstring( ":B1C:" field3, expander.bind(field3, field1_lower, saves, power))

        ; allcapped hotstring
        StringUpper, field1_upper, field1
        StringUpper, field3_upper, field3
        if not negations.item(field3_upper)
            Hotstring( ":B1C:" field3_upper, expander.bind(field3_upper, field1_upper, saves, power))

        ; capped hotstring
        field1_capped := SubStr(field1_upper, 1, 1) . SubStr(field1, 2, (StrLen(field1) - 1))
        field3_capped := SubStr(field3_upper, 1, 1) . SubStr(field3, 2, (StrLen(field3) - 1))
        if not negations.item(field3_capped)
            Hotstring( ":B1C:" field3_capped, expander.bind(field3_capped, field1_capped, saves, power))

        try {
            ; Try the "word" as a hotstring to see whether it exists
            Hotstring( ":B1:" field1 )
        } catch {
            ; The "word" does not exist, so use it as a coaching hint
            Hotstring( ":B0:" field1, hinter.bind(field1, field3, field6, saves, power))
        }
        
        ; if ( NumLines > 800 ) {
        ;     break
        ; }
    }
}

return 

ExpandOutline(lazy, word, saves, power) {
    global expansions
    global phraseEndings
    global lastEndChar
    global TypedCharacters
    global DisplayedCharacters
    
    if (lastEndChar = "'") {
        ; Don't allow contractions to expand the ending
        send, % SubStr(A_ThisHotkey, 6) . A_EndChar
    } else if (A_EndChar = "!") {
        ; Exclam is the ALT character
        send, % word 
        send {!}
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)

    } else {
        send, % word A_EndChar
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(lazy)
    }
    UpdateDashboard()
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


; Allow manual contracting
:?*:'s::'s 
:?*:'d::'d
:?*:'t::'t
:?*:'m::'m
:?*:'re::'re
:?*:'ve::'ve
; Allow "hypenateds-"
:?*:non-::non-
:?*:meta-::meta-
:?*:-q::-q
:?*:`:q::`:q

^j::
	Suspend toggle
    Return

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



LaunchCoach() {
    global MissedText
    global DashboardText
    global AcruedTipText
    global ActiveTipText
    global Opportunities
    ; Define here so each launch refreshes the list
    Opportunities := {}
    
    SysGet, vWidth, 59
    SysGet, vHeight, 60
    
    vWidth := vWidth - 445
    vHeight := vHeight - 1110

    Gui, +AlwaysOnTop +Resize
    Gui,Add,Text,vDashboardText w150 r5, Characters saved in typing
    Gui,Add,Text,vAcruedTipText w200 h520, Shorthand Coach
    Gui,Add,Text,vActiveTipText r1 w200, Last word not shortened
    Gui,Add,Picture, w70 h-1 x170 y5, coach.png
    Gui,Show,w250 h656 x%vWidth% y%vHeight% Minimize, Shorthand Coach
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
    if ( saves < 1) { 
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
    AddOpportunity(hint,saves)
    if (power > 1.5) {
        FlashHint(hint)
    }
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