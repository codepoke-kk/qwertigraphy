 
#SingleInstance Force
#Warn
#NoEnv
SetWorkingDir %A_ScriptDir% 

logFile := ""
LogVerbosity := 4
IfNotExist, logs
    FileCreateDir, logs

logEvent(0, "not logged")
logEvent(1, "not verbose")
logEvent(2, "slightly verbose")
logEvent(3, "pretty verbose")
logEvent(4, "very verbose")

padPages := []
padPages[padPages.Max_Index] := "<path d="" M 29,50 l 1,0"" fill=""none"" stroke=""white"" stroke-width=""2"" />"
pageWidth := 500
guiWidth := .7 * pageWidth
pageHeight := 800
guiHeight := .7 * pageHeight
lineWidth := pageWidth -50
horizontalSpacing := 20
verticalSpacing := 50
nibX := 30
nibY := 50

padPageHeader = ;continuation section
(
<!DOCTYPE html>
<meta http-equiv="X-UA-Compatible" content="IE=9">
<html>
<body>

<svg height="100" width="100">  
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

;display inline svg
Gui, Add, ActiveX, x0 y0 w%guiWidth% h%guiHeight% voWB, shell explorer
Gui, Show, , Gregg Pad

oWB.Navigate("about:blank")

; nibY:  l dx,dy
; arc:   a rx,ry x-axis-rotation large-arc-flag,sweep-flag dx,dy
; curve: c dx1,dy1, dx2,dy2 dx,dy

strokes := ComObjCreate("Scripting.Dictionary")
vowelStrokes := ComObjCreate("Scripting.Dictionary")

; Consonants
strokes.item("n") := "l 15,0"
strokes.item("m") := "l 36,0"
strokes.item("t") := "l 12,-6"
strokes.item("d") := "l 30,-15"
strokes.item("ng") := "l 12,6"
strokes.item("nk") := "l 30,15"
strokes.item("z") := "l -3,8"
strokes.item("c") := "l -6,20"
strokes.item("j") := "l -8,36"
strokes.item("h") := "m 5,5 c 3,0 0,3 0,0"
strokes.item("H") := "m 0,-15 c 3,0 0,3 0,0 m 0,15"
strokes.item("k") := "c 4,-4 21,-9 15,0"
strokes.item("g") := "c 4,-4 45,-12 36,0"
strokes.item("G") := "m -2,10 c 4,-4 45,-12 36,0"
strokes.item("r") := "c -9,9 11,4 15,0"
strokes.item("l") := "c -9,12 28,4 36,0"
strokes.item("s") := "c -4,0 -9,6 -4,8"
strokes.item("p") := "c -4,0 -20,13 -10,20"
strokes.item("b") := "c -4,0 -36,24 -18,36"
strokes.item("S") := "c 4,0 4,2 -4,8"
strokes.item("f") := "c 4,0 12,5 -10,20"
strokes.item("v") := "c 4,0 20,8 -18,36"
strokes.item("th") := "c 3,-6 3,-6 18,-12"
strokes.item("TH") := "c 12,-3 17,-4 18,-12"
strokes.item("nt") := "c 8,0 18,0 24,-16"
strokes.item("nd") := "c 8,0 18,0 24,-16"
strokes.item("mt") := "c 12,0 24,0 36,-20"
strokes.item("md") := "c 12,0 24,0 36,-20"
strokes.item("tn") := "c 0,-4 0,-12 24,-16"
strokes.item("dn") := "c 0,-4 0,-12 24,-16"
strokes.item("tm") := "c 0,-2 0,-20 36,-20"
strokes.item("dm") := "c 0,-2 0,-20 36,-20"
strokes.item("tv") := "c -5,-35 60,-55 10,3"
strokes.item("df") := "c -5,-35 60,-55 10,3"
strokes.item("dv") := "c -5,-35 60,-55 10,3"
strokes.item("ntv") := "l 15,0 c -5,-35 60,-55 10,3"
strokes.item("ndf") := "l 15,0 c -5,-35 60,-55 10,3"
strokes.item("ndv") := "l 15,0 c -5,-35 60,-55 10,3"
strokes.item("jnt") := "c -60,55 15,40 10,3"
strokes.item("jnd") := "c -60,55 15,40 10,3"
strokes.item("pnt") := "c -60,55 15,40 10,3"
strokes.item("pnd") := "c -60,55 15,40 10,3"
strokes.item("ld") := "c -9,12 48,8 36,-8"
strokes.item("dt") := "l 42,-21"
strokes.item("td") := "l 42,-21"
strokes.item("ss") := "c -4,0 -9,6 -4,8 s 1,4 -4,8"
strokes.item("i") := ""
strokes.item("a") := ""
strokes.item("e") := ""
strokes.item("o") := ""
strokes.item("u") := ""
strokes.item("I") := ""
strokes.item("A") := ""
strokes.item("E") := ""
strokes.item("O") := ""
strokes.item("U") := ""

; A
vowelStrokes.item("aDC")  := "c 2,-36 -24,9 0,2" ; 
vowelStrokes.item("aDK")  := "c 4,-36 24,9 0,2" ; 
vowelStrokes.item("aFC")  := "c -27,-16 -5,16 1,2" ; 
;vowelStrokes.item("aFD")  := "c 2,-36 24,9 0,2" ; 
vowelStrokes.item("aFK")  := "c -20,-24 24,0 1,2" ; 
vowelStrokes.item("aLC")  := "c -36,4 9,16 2,0"   ; 
vowelStrokes.item("aLK")  := "c -36,-4 9,-16 2,0"   ; 
vowelStrokes.item("aNDC") := "c -4,36 -36,36 0,2" ; 
vowelStrokes.item("aNUC") := "c -10,30 -48,30 0,2" ; 
vowelStrokes.item("aNUK") := "c 36,-20 8,-20 0,-2" ; 
vowelStrokes.item("aUC")  := "c -27,16 16,9 2,-1"  ; 
vowelStrokes.item("aUK")  := "c -30,16 2,-20 2,-1"  ;
; I
vowelStrokes.item("iDC")  := vowelStrokes.item("aDC")  " l -6,-6 l 6,6" ; 
vowelStrokes.item("iDK")  := vowelStrokes.item("aDK")  " l 6,-6 l -6,6" ; 
vowelStrokes.item("iFC")  := vowelStrokes.item("aFC")  " l -8,-1 l 8,1" ; 
;vowelStrokes.item("iFD")  := vowelStrokes.item("aFD")  "c 2,-36 24,9 0,2" ; 
vowelStrokes.item("iFK")  := vowelStrokes.item("aFK")  " l 2,-6 l -2,6" ; 
vowelStrokes.item("iLC")  := vowelStrokes.item("aLC")  " l -6,6 l 6,-6"   ; 
vowelStrokes.item("iLK")  := vowelStrokes.item("aLK")  " l -6,-6 l 6,6"   ; 
vowelStrokes.item("iNDC") := vowelStrokes.item("aNDC") " l -8,12 l ,-12" ; 
vowelStrokes.item("iNUC") := vowelStrokes.item("aNUC") " l -9,9 l 9,-9" ; 
vowelStrokes.item("iNUK") := vowelStrokes.item("aNUK") " l 9,-6 l -9,6" ; 
vowelStrokes.item("iUC")  := vowelStrokes.item("aUC")  " l -3,6 l 3,-6"  ; 
vowelStrokes.item("iUK")  := vowelStrokes.item("aUK")  " l -8,0 l 8,0"  ;
; E
vowelStrokes.item("eDC") := "c 2,-12 -12,3 0,2" ; 
vowelStrokes.item("eDK") := "c 4,-12 12,3 0,2" ; 
vowelStrokes.item("eFC") := "c -12,0 0,8 1,2" ; 
vowelStrokes.item("eFD") := "c 2,-12 24,3 0,2" ; 
vowelStrokes.item("eFK") := "c 5,-8 8,8 1,2" ; 
vowelStrokes.item("eLC") := "c -12,4 3,9 2,0"   ; 
vowelStrokes.item("eLK") := "c -12,-4 3,-9 2,0"   ; 
vowelStrokes.item("eNDC") := "c -12,9 0,12 0,2" ; 
vowelStrokes.item("eNUC") := "c -16,10 -5,10 0,2" ; 
vowelStrokes.item("eNUK") := "c 0,-12 12,-6 0,-2" ; 
vowelStrokes.item("eUC") := "c -14,5 16,5 2,-1"  ; 
vowelStrokes.item("eUK") := "c -14,-5 2,-7 2,-1"  ;
; O
vowelStrokes.item("oP") := "c 0,8 6,8 6,0" ; 
vowelStrokes.item("oS") := "c -8,0 -8,6 0,6" ; 
; U
vowelStrokes.item("uB") := "c 0,-8 6,-8 6,0" ; 
vowelStrokes.item("uT") := "c 8,0 8,6 0,6" ; 

keysArray := strokes.keys
keysString := ""
For key in keysArray {
    keysString := keysString . key . ","
}
keysString := Trim(keysString, OmitChars := ",")
Sort, keysString, D, F StrokeKeysSort

StrokeKeysSort(a1, a2)
{
    ; Sort by length of key, then alphabetically like normal
    return StrLen(a1) < StrLen(a2) ? 1 : StrLen(a1) > StrLen(a2) ? -1 : a1 > a2 ? 1 : a1 < a2 ? -1 : 0
}
LogEvent(4, "order: " keysString)

vowels := "aeoiuAEIOU"
LogEvent(4, "Initial path: " padPages[padPages.Max_Index])

VisualizeForm("dokumn", "blue")
VisualizeForm("kom", "blue")
VisualizeForm("nun", "blue")
VisualizeForm("pul", "blue")
VisualizeForm("kul", "blue")
VisualizeForm("kut", "blue")
VisualizeForm("ndvat", "blue")
VisualizeForm("at", "blue")
VisualizeForm("At", "blue")
VisualizeForm("kam", "blue")
VisualizeForm("ram", "blue")
VisualizeForm("av", "blue")
VisualizeForm("Av", "blue")
VisualizeForm("aj", "blue")
VisualizeForm("Aj", "blue")
VisualizeForm("jat", "blue")
VisualizeForm("taj", "red")
VisualizeForm("ndvit", "blue")
VisualizeForm("it", "blue")
VisualizeForm("It", "blue")
VisualizeForm("kim", "blue")
VisualizeForm("rim", "blue")
VisualizeForm("iv", "blue")
VisualizeForm("Iv", "blue")
VisualizeForm("ij", "blue")
VisualizeForm("Ij", "blue")
VisualizeForm("jit", "blue")
VisualizeForm("tij", "red")
VisualizeForm("ndvet", "blue")
VisualizeForm("et", "blue")
VisualizeForm("Et", "blue")
VisualizeForm("kem", "blue")
VisualizeForm("rem", "blue")
VisualizeForm("ev", "blue")
VisualizeForm("Ev", "blue")
VisualizeForm("Ev", "blue")
VisualizeForm("ej", "blue")
VisualizeForm("Ej", "blue")
VisualizeForm("jet", "blue")
VisualizeForm("tej", "red")

return

GuiClose:
    logEvent(1, "App exit called")
    ExitApp

VisualizeForm(form, pen) {
    global oWB
    global strokes
    global vowelStrokes
    global keysString
    global key
    global padPages
    global padPageHeader
    global padPageFooter
    global padPageBackground
    global nibX
    global nibY
    global horizontalSpacing
    global verticalSpacing
    global lineWidth
    global vowels
    
    LogEvent(4, "Visualing form " form)
    
    ; thisForm will hold the finished Shorthand form 
    thisForm := "<path d=""m " nibX "," nibY " "
    preceding := ""
    ; Loop until the code breaks out after representing the last stroke
    Loop {  
        startLength := StrLen(form)
        ; Loop across all defined strokes, looking for one with which the form begins 
        for index, key in StrSplit(keysString, ",") { 
            LogEvent(4, "Working ^" key " with " strokes.item(key))
            newForm := RegExReplace(form, "^" key, Replacement := "")
            if (newForm != form) {
                LogEvent(4, "Found " key " leaving " newForm)
                
                ; modify vowels based upon the preceding and following characters
                if (RegexMatch(vowels, key)) {
                    following := SubStr(newForm, 1, 1)
                    LogEvent(4, "Found vowel as " preceding "." key "." following)
                    vowelKey := SelectVowelForm(preceding, key, following)
                    thisPath := vowelStrokes.item(vowelKey)
                    LogEvent(4, "Adding " thisPath " ")
                } else {
                    LogEvent(4, "Adding " strokes.item(key) " ")
                    thisPath := strokes.item(key) " "
                }
                
                ; Check for empty thisPath 
                LogEvent(4, "thisPath is " StrLen(thisPath) " characters long")
                if (StrLen(thisPath) == 0) {
                    LogEvent(4, "Filling empty thisPath")
                    thisPath := FillMissingCharacter()
                }
                thisForm := thisForm . thisPath " "
                nibX += AdvanceNib(thisPath)
                form := newForm
                preceding := key
                break
            } else {
                LogEvent(4, "Did not find " key)
            }
        }
        
        ; We broke out. Handle the found stroke, then keep looping for the next 
        if (startLength != StrLen(form)) {
            ; The form key is shorter, so we found something 
            LogEvent(4, "Identified something. Continuing")
            if (! StrLen(form)) {
                LogEvent(4, "Form fully parsed")
                break
            }
        } else {
            ; The form key is the same length, so we hit an undefined character 
            LogEvent(4, "Unidentified character in form: " form)
            Msgbox, % "Unidentified character in form: " form
            ;thisPath := fill=""none"" stroke=""" pen """ stroke-width=""2"" />"
            ;thisForm := thisForm . thisPath " "
            ;nibX += AdvanceNib(thisPath)
            ;preceding := key
            break
        }
    }
    thisForm := thisForm . """ fill=""none"" stroke=""" pen """ stroke-width=""2"" />"
    nibX += horizontalSpacing
    if (nibX > lineWidth) {
        nibX := horizontalSpacing
        nibY += verticalSpacing
    }
    
    padPages[padPages.Max_Index] := padPages[padPages.Max_Index] . thisForm
    LogEvent(2, "Final path: " padPages[padPages.Max_Index])
    
    fullLine := padPages[padPages.Max_Index]
    padPageContent = %padPageHeader%%padPageBackground%%fullline%%padPageFooter%

    logEvent(4, "Final pad page " padPageContent)
    oWB.document.write(padPageContent)
    oWB.Refresh()
    Gui, Show, AutoSize Center
}

SelectVowelForm(preceding, vowel, following) {
    global strokes
    global vowelStrokes
    
    series := SubStr(preceding, 0, 1) . vowel . SubStr(following, 1, 1) 
    LogEvent(3, "Choosing vowel based upon " preceding "." vowel "." following " as " series)
    
    
    ; Taken markers: ULFDNCKPSBT
    ; All consonants: spbSfvtdnmkgrlzcj
    ; All vowels: aeiou
    
    
    ; AEI
    ; Direction
    upward := "(^[tdSfv][aieAEI])|(^[aieAEI][td])"
    level := "(^[hnmrgkl][aieAEI])|(^[aieAEI][hnmrgkl])"
    falling := "(^(([spb][aieAEI])|ng|nk))|(^[aieAEI][spbfv])"
    down := "(^[zcj][aieAEI])|(^[aieAEI][zcj])"
    ; Shape
    narrow := "([zcjSfv][aieAEI][td])|[td][aieAEI][zcj]"
    clockwise := "((^[Sfvkg][aeiAEI])|(^[aeiAEI][Sfvkgtdnmzcj])|([spb][aeiAEI][tdnmkg])|([td][aeiAEI][td])|([nm][aeiAEI][tdnmkg])|([zcj][aeiAEI][Sfvtdnmkgzcj]))"
    kounterclockwise := "((^[rl])|(^[aeiAEI][spbrl])|([spb][aeiAEI][spbSfvrl])|([tdnm][aeiAEI][spbSfvnmrlzcj])|([zcj][aeiAEI][spbrl]))"
    reverser := "[AEI]"
    
    ; O
    puddle := "([oO][spbSfvtdkgzcj])|([spbSfvzcj][oO][nmrl])"
    spill := "([^spbSfvzcj][oO][nmrl])"
    
    ; U
    bump := "([spbSfvtdrlzcj][uU])|([kg][uU][^rl])"
    trap := "([nm][uU])|([kg][uU][rl])"
    
    
    StringLower, selection, vowel
    
    if (RegexMatch(series, narrow)) {
        selection := selection "N"
    }
    
    if (RegexMatch(series, upward)) {
        selection := selection "U"
    } else if (RegexMatch(series, level)) {
        selection := selection "L"
    } else if (RegexMatch(series, falling)) {
        selection := selection "F"
    } else if (RegexMatch(series, down)) {
        selection := selection "D"
    } else {
        LogEvent(4, "Picking direction failed with no match on """ series """")
    }
    
    if (RegexMatch(series, clockwise)) {
        if (! RegexMatch(series, reverser)) {
            selection := selection "C"
        } else {
            selection := selection "K"
        }
    } else if (RegexMatch(series, kounterclockwise)) {
        if (! RegexMatch(series, reverser)) {
            selection := selection "K"
        } else {
            selection := selection "C"
        }
    } else {
        LogEvent(4, "Picking rotation failed with no match on """ series """")
    }
    
    if (RegexMatch(series, puddle)) {
        selection := selection "P"
    } else if (RegexMatch(series, spill)) {
        selection := selection "S"
    } else {
        LogEvent(4, "Picking puddle/spill failed with no match on """ series """")
    }
    
    if (RegexMatch(series, bump)) {
        selection := selection "B"
    } else if (RegexMatch(series, trap)) {
        selection := selection "T"
    } else {
        LogEvent(4, "Picking bump/trap failed with no match on """ series """")
    }
    
    if (! vowelStrokes.item(selection)) {
        LogEvent(1, "Need to create vowel stroke for """ series """  selects """ selection """")
        Msgbox, % "Need to create vowel for " selection
    }
    
    LogEvent(3, "Chose " selection)
    Return selection
}

AdvanceNib(path) {
    LogEvent(4, "Advancing nib column-wise per " path)
    subPaths := StrSplit(path, StrSplit("c,l", ","))
    advance := 1
    Loop % subPaths.MaxIndex() {
        subPath := subPaths[A_Index]
        FoundPos := RegExMatch(subPath, "O)(-?\d+),-?\d+ ?$" , Matches)
        deltaX := Abs(Matches[1] + 0)
        advance += deltaX
        LogEvent(2, "Advance nib " deltaX " pixels and total of " advance " for subpath " subpath)
    }
    LogEvent(2, "Total advance of nib " advance " pixels for path " path)
    Return advance
}

FillMissingCharacter() {
    Return "l 3,-3 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,3"
}

LogEvent(verbosity, message) {
    global logFileName
    global logFile
    global logVerbosity
    if (not verbosity) or (not logVerbosity)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFile) {
        logFileName := "coach." . logDateStamp . ".log"
        logFile := FileOpen("logs\" logFileName, "a")
        logFile.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= logVerbosity) 
        logFile.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}