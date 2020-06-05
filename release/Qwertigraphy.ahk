
hasNotLaunchedCoach := 1
wordsExpanded := 0
charsSaved := 0
lastExpandedWord := ""

#Hotstring EndChars -()[]{}:;'"/\,.?!`n `t
#Include cmu_dictionary.ahk
#Include phrases.ahk
#Include phrase_coaching.ahk
#Include cmu_coaching.ahk


:C:w::we
:C:W::We

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
    ; Track each word as expanded in order to make sure we don't coach it
    global lastExpandedWord
    lastExpandedWord := word . A_EndChar
    sendlevel, 1
    send, % word . A_EndChar ; . " for " . SubStr(A_ThisHotkey, 5)
    sendlevel, 0
}

FlashTip(tip) {
    Tooltip %tip%, A_CaretX, A_CaretY + 30
    Sleep 1500
    ToolTip
}
^#p::
    LaunchCoach()
    Return
    
LaunchCoach() {
    global AcruedTipText
    global ActiveTipText
    global Opportunities
    Opportunities := {}
    
    SysGet, vWidth, 78
    SysGet, vHeight, 79
    
    vWidth := vWidth - 280
    vHeight := vHeight - 700

    Gui, +AlwaysOnTop +Resize
    Gui,Add,Text,vAcruedTipText w200 h550, Shorthand Coach
    Gui,Add,Text,vActiveTipText w200, Shorthand Coach
    Gui,Show,w250 h600 x%vWidth% y%vHeight%, Shorthand Coach

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
   ; If we just expanded this word, don't coach it
    global lastExpandedWord
    if (A_ThisHotkey = ":*b0:" . lastExpandedWord) {
        ; Msgbox, % "Ignore " A_PriorHotkey
        Return
    }
    
    ; If we've not yet launched the coach, do so
    global hasNotLaunchedCoach
    if ( hasNotLaunchedCoach ) {
        LaunchCoach()
        hasNotLaunchedCoach := 0
    }
    tip := outline " = " word
    AddOpportunity(tip,saves)
    
    ; MsgBox % tip
    if (power > 1.9) {
        FlashTip(tip)
    }
}