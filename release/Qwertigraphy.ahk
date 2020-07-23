
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

#NoEnv 
#Warn 
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1
SetKeyDelay, -1

;#Hotstring EndChars -()[]{}:;'"/\,.?!`n `t
#Include cmu_dictionary.ahk
#Include phrases.ahk
#Include cmu_coaching.ahk
#Include phrase_expansions.ahk


; ctrl-win-space expands a word in place
^#Space::
    ; Msgbox, % "Spaceing"
    SendLevel, 1
    Send, {Space}
    SendLevel, 0
    Sleep, 20
    Send, {bs}
    Return 

; Allow manual contracting
:?*:'s::'s 
:?*:'d::'d
:?*:'t::'t
:?*:'m::'m
:?*:'re::'re
:?*:'ve::'ve

; Contractions
:CX:im::Expand("I'm")
:CX:Im::Expand("I'm")

; Allow cancellation or expansion with backtick
^`::
    ; Cancel expansion on Ctrl
    hotstring("reset")
    Return 
!`::
    ; Expand in place on Alt
    ; Msgbox, % "Spacing"
    SendLevel, 1
    Send, {Space}
    SendLevel, 0
    Sleep, 20
    Send, {bs}
    Return 
#`::
    ; Expand in place on Win
    ; Msgbox, % "Spacing"
    SendLevel, 1
    Send, {Space}
    SendLevel, 0
    Sleep, 20
    Send, {bs}
    Return

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

CoordMode Caret

Expand(word) {
    global expansions
    global phraseEndings
    global lastEndChar
    global TypedCharacters
    global DisplayedCharacters
    
    if (lastEndChar = "'") {
        ; Don't allow contractions to expand the ending
        send, % SubStr(A_ThisHotkey, 5) . A_EndChar
    } else {
        if (A_EndChar = "!") {
            ; Exclam is the ALT character
            send, % word 
            send {!}
        } else {
            send, % word A_EndChar
        }
        DisplayedCharacters += StrLen(word)
        TypedCharacters += StrLen(SubStr(A_ThisHotkey, 5))
        UpdateDashboard()
    }
    lastEndChar := A_EndChar
    hotstring("reset")
}

FlashTip(tip) {
    Tooltip %tip%, A_CaretX, A_CaretY + 30
    SetTimer, ClearToolTip, -1500
    return 

    ClearToolTip:
      ToolTip
    return 
}
^#p::
    LaunchCoach()
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
CoachOutline(word, outline, saves, power) {
    ; If we've not yet launched the coach, do so
    global hasNotLaunchedCoach
    if ( hasNotLaunchedCoach ) {
        LaunchCoach()
        LoadPhraseExpansions()
        hasNotLaunchedCoach := 0
    }
    tip := outline " = " word
    AddOpportunity(tip,saves)
    
    ; MsgBox % tip
    if (power > 1.9) {
        FlashTip(tip)
    }
}