
csv := "outlines_final.csv"
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

Loop,Read,%csv%   ;read dictionary into HotStrings
{
    Global NumLines
    NumLines:=A_Index-1
    IfEqual, A_Index, 1, Continue ; Skip title row
    Loop,Parse,A_LoopReadLine,CSV   ;parse line into 6 fields
    {
        ; msgbox % "Making field" A_Index " = " A_LoopField
        field%A_Index% = %A_LoopField%
    }
    ; msgbox % "Making " field3 " = " field1 " hinting " field6
    ; words[field3] := field1
    ; hints[field1] := field6
    ; Use fields to define hotstrings
    ; Hotstring( ":B1:" field3, expander.bind(field3, field1))
    Hotstring( ":B1:" field3, field1)
    try {
        ; Don't allow hint hotstrings to overwrite live ones
        Hotstring( ":B1:" field1 )
    } catch {
        Hotstring( ":B0:" field1, hinter.bind(field1, field3, field6))
    }
    
    ; if ( NumLines > 800 ) {
    ;     break
    ; }
}
Msgbox % "Fully initialized"

return 

ExpandOutline(lazy, word) {
    ; send, % "lazy: " lazy ", word: " word
    send, % word A_EndChar
}
FlashHint(hint) {
    Tooltip %hint%, A_CaretX, A_CaretY + 30
    SetTimer, ClearToolTip, -1500
    return 

    ClearToolTip:
      ToolTip
    return 
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


; Allow manual contracting
:?*:'s::'s 
:?*:'d::'d
:?*:'t::'t
:?*:'m::'m
:?*:'re::'re
:?*:'ve::'ve


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
}
ListOpportunities(opps) {
  summaries := ""
  for summary,count in opps {
    summaries .= SubStr("000", StrLen(count)) count ": " summary "`n"
  }
  Sort, summaries, R
  return Trim(summaries, "`n")
}
CoachOutline(word, outline, hint) {
    ; If we've not yet launched the coach, do so
    global hasNotLaunchedCoach
    saves := StrLen(word) - StrLen(outline)
    power := StrLen(word) / StrLen(outline)
    ; if ( hasNotLaunchedCoach ) {
    ;     LaunchCoach()
    ;     ; LoadPhraseExpansions()
    ;     hasNotLaunchedCoach := 0
    ; }
    AddOpportunity(hint,saves)
    
    ; MsgBox % tip
    if (power > 1.8) {
        FlashHint(hint)
    }
}