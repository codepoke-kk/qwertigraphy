
hasNotLaunchedCoach := 1
wordsExpanded := 0
charsSaved := 0
lastExpandedWord := ""
lastEndChar := ""
expansions := ""
phraseEndings := {}

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
	Suspend toggle
	Suspend toggle
    Send {Space}
    Return
^.::
	Suspend toggle
	Suspend toggle
    Send {.}
    Return
^,::
	Suspend toggle
	Suspend toggle
    Send {,}
    Return
+^;::
	Suspend toggle
	Suspend toggle
    Send {:}
    Return
^Tab::
	Suspend toggle
	Suspend toggle
    Send {Tab}
    Return
^Enter::
	Suspend toggle
	Suspend toggle
    Send {Enter}
    Return

CoordMode Caret

Expand(word) {
    global expansions
    global phraseEndings
    global lastEndChar
    if (lastEndChar = "'") {
        ; Don't allow contractions to expand the ending
        send, % SubStr(A_ThisHotkey, 5) . A_EndChar 
    } else {
        send, % word . A_EndChar
    }
    
    expansions .= word . A_EndChar
    expansions := SubStr(expansions, -40)
    if (phraseEndings[word]) 
    {
        For outline,expansion in phraseEndings[word]
        {
            if (InStr(expansions, expansion, , StrLen(expansions) - StrLen(expansion)) ) 
            {
                firstOutline := SubStr(outline, 1, InStr(outline, ",")-1)
                saves := StrLen(expansion) - StrLen(firstOutline)
                power := StrLen(expansion) / StrLen(firstOutline)
                CoachOutline(expansion, outline, saves, power)
            }
        }
    }
    
    lastEndChar := A_EndChar
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
    global AcruedTipText
    global ActiveTipText
    global Opportunities
    Opportunities := {}
    
    SysGet, vWidth, 59
    SysGet, vHeight, 60
    
    vWidth := vWidth - 445
    vHeight := vHeight - 1010

    Gui, +AlwaysOnTop +Resize
    Gui,Add,Text,vAcruedTipText w200 h550, Shorthand Coach
    Gui,Add,Text,vActiveTipText w200, Shorthand Coach
    Gui,Show,w250 h600 x%vWidth% y%vHeight% Minimize, Shorthand Coach

}

AddOpportunity(tip,saves) {
    global Opportunities
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