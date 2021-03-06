 
#SingleInstance Force
#Warn
#NoEnv
SetWorkingDir %A_ScriptDir% 

padPageFile := "greggpad.html"
if (A_ScriptName == "GreggPad.ahk") {
    Gregging := True
    Qwerting := True
    FreeStandingGreggPad := True
} else {
    FreeStandingGreggPad := False
}

logFileGP := ""
logVerbosityGP := 2
IfNotExist, logs
    FileCreateDir, logs

LogEventGP(0, "not logged")
LogEventGP(1, "not verbose")
LogEventGP(2, "slightly verbose")
LogEventGP(3, "pretty verbose")
LogEventGP(4, "very verbose")

padPages := []
padPagesIndex := 0
padPages[padPagesIndex] := "<path d="" M 29,50 l 1,0"" fill=""none"" stroke=""white"" stroke-width=""2"" />"
pageWidth := 500
guiWidth := pageWidth
pageHeight := 800
guiHeight := pageHeight
lineWidth := pageWidth -50
horizontalSpacing := 20
verticalSpacing := 70
qwertingVertical := 50
averageLetterWidth := 8
nibX := horizontalSpacing
nibY := verticalSpacing

padPageHeader = ;continuation section
(
<!DOCTYPE html>
<meta http-equiv="X-UA-Compatible" content="IE=9">
<html>
<body>

<svg id="GreggPad" height="100" width="100">  
)

padPageFooter =     
(
Sorry, your browser does not support inline SVG.
</svg>

</body>
</html>
)

padPageBackground := "<rect x=""1"" y=""1"" width=""" pageWidth """ height=""" pageHeight """ fill=""cornsilk"" />`n"
padPageBackground := padPageBackground "<path d=""M " (pageWidth - 20) ",0 l 0," pageHeight """  fill=""none"" stroke=""skyblue"" stroke-width=""1"" />`n"

lineY := nibY + 4
Loop {
    padPageBackground := padPageBackground "<path d=""M 0," lineY " l 500,00""  fill=""none"" stroke=""salmon"" stroke-width=""1"" />`n"
    lineY += verticalSpacing
    if (lineY > pageHeight) {
        Break
    }
}

; nibY:  l dx,dy
; arc:   a rx,ry x-axis-rotation large-arc-flag,sweep-flag dx,dy
; curve: c dx1,dy1, dx2,dy2 dx,dy

strokes := ComObjCreate("Scripting.Dictionary")
vowelStrokes := ComObjCreate("Scripting.Dictionary")
#Include strokes.ahk
keysArray := strokes.keys

vowels := "-a-e-o-i-u-"
LogEventGP(4, "Initial path: " padPages[padPagesIndex])

; Uniquely shaped consonants: b,v,d,m,g,l,j
; Uniquely shaped blends: dm, md, dv, jnd 
;VisualizeForm("Gregg", "g-r-e-g", "blue")
;VisualizeForm("Pad", "p-a-d", "blue")
;VisualizeForm("bro", "br-o", "red")
;VisualizeForm("blo", "bl-o", "red")

;display inline svg
if (Gregging) {
    ShowGreggPad()
}

GreggPadGuiClose:
    LogEventGP(1, "App exit called")
    if (FreeStandingGreggPad) {
        ExitApp
    } else {
        Gregging := false
        Gui GreggPad:Default
        Gui Destroy
        Gui Qwertigraph:Default
        GuiControl, , GreggingCheckbox, 0
    }
    
ShowGreggPad() {
    local
    global guiWidth
    global guiHeight
    global oWB
        
    Gui GreggPad:Default
    Gui, -dpiscale +Resize
    Gui, GreggPad:Add, ActiveX, x0 y0 w%guiWidth% h%guiHeight% voWB, internet.explorer
    Gui, GreggPad:Show, , Gregg Pad

    ;oWB.Navigate("about:blank")
    ;oWB.Refresh()
    
    VisualizeForm("Gregg", "g-r-e-g", "blue")
    VisualizeForm("Pad", "p-a-d", "blue")
}

VisualizeForm(qwerd, form, pen) {
    local
    Global Gregging
    Global Qwerting
    global oWB
    global strokes
    global vowelStrokes
    global padPages
    global padPagesIndex
    global padPageHeader
    global padPageFooter
    global padPageBackground
    global nibX
    global nibY
    global horizontalSpacing
    global verticalSpacing
    global qwertingVertical
    global averageLetterWidth
    global lineWidth
    global pageHeight
    global vowels
    global padPageFile
    
    if (! Gregging) {
        return
    }
    
    LogEventGP(2, "Visualing form " form)
    
    formStrokes := StrSplit(form, "-")
    
    ; thisForm will hold the finished Shorthand form 
    if (Qwerting) {
        thisQwerd := "<text x=""" nibx """ y=""" (nibY+qwertingVertical) """ fill=""" pen """>" qwerd "</text>" 
        qwertNibX := nibX + (averageLetterWidth * StrLen(qwerd))
    } else {
        thisQwerd := ""
        qwertNibX := 0
    }
    thisForm := thisQwerd "<!-- encoding " form " --><path d=""M " nibX "," nibY " "
    preceding := ""
    for fsindex, formStroke in formStrokes { 
        LogEventGP(4, "Working formStroke " formStroke)
        
        ; modify vowels based upon the preceding and following characters
        if (InStr("a,a2,e,e2,i,i2,o,o2,u,u2,ea,ea2", formStroke)) {
            following := formStrokes[(fsindex + 1)]
            LogEventGP(2, "Found vowel as " preceding "-" formStroke "-" following)
            vowelKey := SelectVowelForm(preceding, formStroke, following)
            thisPath := vowelStrokes.item(vowelKey)
            LogEventGP(4, "Adding " thisPath " ")
        } else {
            LogEventGP(4, "Adding " strokes.item(formStroke) " ")
            thisPath := strokes.item(formStroke)
        }
            
        ; Check for empty thisPath 
        LogEventGP(4, "thisPath is " StrLen(thisPath) " characters long")
        if (StrLen(thisPath) <= 1) {
            LogEventGP(2, "Unable to visualize " formStroke " in " form)
            thisPath := FillMissingCharacter()
        }
        thisForm := thisForm . thisPath " "
        nibX += AdvanceNib(thisPath)
        preceding := formStroke
    }
    thisForm := thisForm . """ fill=""none"" stroke=""" pen """ stroke-width=""2"" />`n"
    if (Qwerting) {
        if (nibX < qwertNibX) {
            nibX := qwertNibX
        }
    }
    nibX += horizontalSpacing
    if (nibX > lineWidth) {
        nibX := horizontalSpacing
        nibY += verticalSpacing
        if (Qwerting) {
            nibY += qwertingVertical
        }
    }
    
    LogEventGP(4, "Adding thisForm to page " padPagesIndex ": " thisForm)
    padPages[padPagesIndex] := padPages[padPagesIndex] . thisForm
    LogEventGP(3, "Final path: " padPages[padPagesIndex])
    
    fullLine := padPages[padPagesIndex]
    padPageContent = %padPageHeader%%padPageBackground%%fullline%%padPageFooter%
    
    FileDelete, %padPageFile%
    FileAppend, %padPageContent%, %padPageFile%

    LogEventGP(4, "Final pad page " padPageContent)
    oWB.Navigate(A_ScriptDir "/" padPageFile)
    
    ; Only now if we need a new page, turn it
    if (nibY > (pageHeight - verticalSpacing - qwertingVertical)) {
        nibY := verticalSpacing
        padPagesIndex += 1
        padPages[padPagesIndex] := "<path d="" M 29,50 l 1,0"" fill=""none"" stroke=""white"" stroke-width=""2"" />"
        ; Msgbox, % "We need a new page and now max index is " padPagesIndex
    }
}

SelectVowelForm(preceding, vowel, following) {
    local
    global strokes
    global vowelStrokes
    
    LogEventGP(2, "Choosing vowel based upon " preceding "." vowel "." following)
    
    ; Uniquely shaped consonants: b,v,d,m,g,l,j
    ; Uniquely shaped blends: dm, md, dv, jnd 
    ; All vowels: aeiou
    if (InStr(",<,^,>,\,/,", "," preceding ",")) {
        preceding := ""
    } else if (InStr(",s,p,b,", "," preceding ",")) {
        preceding := "b"
    } else if (InStr(",s2,f,v,", "," preceding ",")) {
        preceding := "v"
    } else if (InStr(",t,d,", "," preceding ",")) {
        preceding := "d"
    } else if (InStr(",n,m,nm,mn,", "," preceding ",")) {
        preceding := "m"
    } else if (InStr(",k,g,", "," preceding ",")) {
        preceding := "g"
    } else if (InStr(",r,l,pr,br,pl,bl,", "," preceding ",")) {
        preceding := "l"
    } else if (InStr(",z,c,j,", "," preceding ",")) {
        preceding := "j"
    } else if (InStr(",tn,tm,dn,dm,", "," preceding ",")) {
        preceding := "m"
    } else if (InStr(",nt,mt,nd,md,", "," preceding ",")) {
        preceding := "d"
    } else if (InStr(",tf,df,df,dv,", "," preceding ",")) {
        preceding := "v"
    } else if (InStr(",jnd,jnt,", "," preceding ",")) {
        preceding := "jnd"
    }
    if (InStr(",<,^,>,\,/,", "," following ",")) {
        following := ""
    } else if (InStr(",s,p,b,", "," following ",")) {
        following := "b"
    } else if (InStr(",s2,f,v,", "," following ",")) {
        following := "v"
    } else if (InStr(",t,d,", "," following ",")) {
        following := "d"
    } else if (InStr(",n,m,nm,mn,", "," following ",")) {
        following := "m"
    } else if (InStr(",k,g,", "," following ",")) {
        following := "g"
    } else if (InStr(",r,l,pr,br,pl,bl,", "," following ",")) {
        following := "l"
    } else if (InStr(",z,c,j,", "," following ",")) {
        following := "j"
    } else if (InStr(",tn,tm,dn,dm,", "," following ",")) {
        following := "d"
    } else if (InStr(",nt,mt,nd,md,", "," following ",")) {
        following := "m"
    } else if (InStr(",tf,df,df,dv,", "," following ",")) {
        following := "d"
    } else if (InStr(",jnd,jnt,", "," following ",")) {
        following := "jnd"
    }
    
    series := preceding . vowel . following
    LogEventGP(2, "Transformed vowel selection to " series)
    
    
    if (! vowelStrokes.item(series)) {
        series := preceding . vowel 
        if (! vowelStrokes.item(series)) {
            series := vowel
            if (! vowelStrokes.item(series)) {
                LogEventGP(1, "Need to create vowel stroke for """ series """")
            }
        }
    }
    
    Return series
}

AdvanceNib(path) {
    local
    
    LogEventGP(4, "Advancing nib column-wise per " path)
    subPaths := StrSplit(path, StrSplit("c,l", ","))
    advance := 1
    Loop % subPaths.MaxIndex() {
        subPath := subPaths[A_Index]
        FoundPos := RegExMatch(subPath, "O)(-?\d+),-?\d+ ?$" , Matches)
        deltaX := Abs(Matches[1] + 0)
        advance += deltaX
        LogEventGP(3, "Advance nib " deltaX " pixels and total of " advance " for subpath " subpath)
    }
    LogEventGP(3, "Total advance of nib " advance " pixels for path " path)
    Return advance
}

FillMissingCharacter() {
    Return "l 3,-3 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,3"
}

LogEventGP(verbosity, message) {
    global logFileGPName
    global logFileGP
    global logVerbosityGP
    if (not verbosity) or (not logVerbosityGP)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFileGP) {
        logFileGPName := "GreggPad." . logDateStamp . ".log"
        logFileGP := FileOpen("logs\" logFileGPName, "a")
        logFileGP.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= logVerbosityGP) 
        logFileGP.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}