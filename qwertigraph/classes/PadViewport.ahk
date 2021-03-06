

padViewer := {}

global oWB := ""
global strokes := ComObjCreate("Scripting.Dictionary")
global vowelStrokes := ComObjCreate("Scripting.Dictionary")
#Include classes\strokes.ahk

Gui, Tab, GreggPad
Gui, Add, ActiveX, x12 y64 w826 h476 voWB, internet.explorer
oWB.Navigate(A_ScriptDir "\greggpad.html" )

class PadViewport
{
	penQueue := {}
	interval := 1000
	penEvents := []
	logQueue := new Queue("PadQueue")
	logVerbosity := 1
	
	padPageFile := "greggpad.html"
	padPages := []
	padPagesIndex := 0
	pageWidth := 826
	guiWidth := this.pageWidth
	pageHeight := 476
	guiHeight := this.pageHeight
	lineWidth := this.pageWidth -50
	horizontalSpacing := 20
	verticalSpacing := 70
	qwertingVertical := 50
	averageLetterWidth := 8
	nibX := this.horizontalSpacing
	nibY := this.verticalSpacing
	lineY := this.nibY + 4
	qwerting := 1

	; nibY:  l dx,dy
	; arc:   a rx,ry x-axis-rotation large-arc-flag,sweep-flag dx,dy
	; curve: c dx1,dy1, dx2,dy2 dx,dy

	keysArray := strokes.keys

	vowels := "-a-e-o-i-u-"
	;this.LogEvent(4, "Initial path: " this.padPages[padPagesIndex])

	; Uniquely shaped consonants: b,v,d,m,g,l,j
	; Uniquely shaped blends: dm, md, dv, jnd 
	;VisualizeForm("Gregg", "g-r-e-g", "blue")
	;VisualizeForm("Pad", "p-a-d", "blue")
	;VisualizeForm("bro", "br-o", "red")
	;VisualizeForm("blo", "bl-o", "red")


	
	__New(penQueue)
	{
		this.penQueue := penQueue
		
        this.timer := ObjBindMethod(this, "DequeueEvents")
        timer := this.timer
        SetTimer % timer, % this.interval
		
		this.padPages[this.padPagesIndex] := "<path d="" M 29,50 l 1,0"" fill=""none"" stroke=""white"" stroke-width=""2"" />"
		this.padPageHeader := "<!DOCTYPE html><meta http-equiv=""X-UA-Compatible"" content=""IE=9""><html><body><svg id=""GreggPad"" height=""" this.pageHeight """ width=""" this.pageWidth """>"
		this.padPageFooter := "Sorry, your browser does not support inline SVG.</svg></body></html>"
		this.padPageBackground := "<rect x=""1"" y=""1"" width=""" this.pageWidth """ height=""" this.pageHeight """ fill=""cornsilk"" />`n"
		this.padPageBackground := this.padPageBackground "<path d=""M " (this.pageWidth - 20) ",0 l 0," this.pageHeight """  fill=""none"" stroke=""skyblue"" stroke-width=""1"" />`n"
			
		Loop {
			this.padPageBackground := this.padPageBackground "<path d=""M 0," this.lineY " l " this.pageWidth ",00""  fill=""none"" stroke=""salmon"" stroke-width=""1"" />`n"
			this.lineY += this.verticalSpacing
			if (this.lineY > this.pageHeight) {
				Break
			}
		}

		this.showPadPage("")
		this.LogEvent(2, "GreggPad initialized")
		
	}
	
	DequeueEvents() {
		this.LogEvent(4, "Dequeueing pen events for " this.penQueue.getSize())
		Loop, % this.penQueue.getSize() {
			penAction := this.penQueue.dequeue()
			this.LogEvent(3, "Dequeued event for " penAction.form)
			this.penEvents.Push(penAction)
			if (penAction.form) {
				this.visualizeForm(penAction.qwerd, penAction.form, penAction.ink)
			} else {
				this.visualizeForm(penAction.word, "h", penAction.ink)
			}
		}
	}
	
	showPadPage(penActions) {

		this.LogEvent(4, "Adding " penActions)
		padPageContent := this.padPageHeader this.padPageBackground penActions this.padPageFooter
		
		FileDelete, % this.padPageFile
		FileAppend, % padPageContent, % this.padPageFile

		this.LogEvent(4, "Final pad content " padPageContent)
		this.LogEvent(4, "Pad location " A_ScriptDir "\" this.padPageFile)
		oWB.Navigate(A_ScriptDir "\" this.padPageFile)
		this.LogEvent(4, "Went there")
	}
	
	visualizeForm(qwerd, form, pen) {
		
		this.LogEvent(2, "Visualing form '" form "' and '" qwerd "' in " pen)
		
		formStrokes := StrSplit(form, "-")
		
		; thisForm will hold the finished Shorthand form 
		if (this.qwerting) {
			thisQwerd := "<text x=""" this.nibx """ y=""" (this.nibY + this.qwertingVertical) """ fill=""" pen """>" qwerd "</text>" 
			qwertNibX := this.nibX + (this.averageLetterWidth * StrLen(qwerd))
		} else {
			thisQwerd := ""
			qwertNibX := 0
		}
		thisForm := thisQwerd "<!-- encoding " form " --><path d=""M " this.nibX "," this.nibY " "
		preceding := ""
		for fsindex, formStroke in formStrokes { 
			this.LogEvent(4, "Working formStroke " formStroke)
			
			; modify vowels based upon the preceding and following characters
			if (InStr("a,a2,e,e2,i,i2,o,o2,u,u2,ea,ea2", formStroke)) {
				following := formStrokes[(fsindex + 1)]
				this.LogEvent(2, "Found vowel as " preceding "-" formStroke "-" following)
				vowelKey := this.selectVowelForm(preceding, formStroke, following)
				thisPath := vowelStrokes.item(vowelKey)
				this.LogEvent(4, "Adding " thisPath " ")
			} else {
				this.LogEvent(4, "Adding " strokes.item(formStroke) " ")
				thisPath := strokes.item(formStroke)
			}
				
			; Check for empty thisPath 
			this.LogEvent(4, "thisPath is " StrLen(thisPath) " characters long")
			if (StrLen(thisPath) <= 1) {
				this.LogEvent(2, "Unable to visualize " formStroke " in " form)
				thisPath := this.fillMissingCharacter()
			}
			thisForm := thisForm . thisPath " "
			this.nibX += this.advanceNib(thisPath)
			preceding := formStroke
		}
		thisForm := thisForm . """ fill=""none"" stroke=""" pen """ stroke-width=""2"" />`n"
		if (this.qwerting) {
			if (this.nibX < qwertNibX) {
				this.nibX := qwertNibX
			}
		}
		this.nibX += this.horizontalSpacing
		if (this.nibX > this.lineWidth) {
			this.nibX := this.horizontalSpacing
			this.nibY += this.verticalSpacing
			if (this.qwerting) {
				this.nibY += this.qwertingVertical
			}
		}
		
		this.LogEvent(4, "Adding thisForm to page " this.padPagesIndex ": " thisForm)
		this.padPages[this.padPagesIndex] := this.padPages[this.padPagesIndex] . thisForm
		this.LogEvent(3, "Final path: " this.padPages[this.padPagesIndex])
		
		fullLine := this.padPages[this.padPagesIndex]
		this.showPadPage(fullLine)
		
		; Only now if we need a new page, turn it
		if (this.nibY > (this.pageHeight - this.verticalSpacing - this.qwertingVertical)) {
			this.nibY := this.verticalSpacing
			this.padPagesIndex += 1
			this.padPages[this.padPagesIndex] := "<path d="" M 29,50 l 1,0"" fill=""none"" stroke=""white"" stroke-width=""2"" />"
			; Msgbox, % "We need a new page and now max index is " padPagesIndex
		}
	}

	selectVowelForm(preceding, vowel, following) {
		
		this.LogEvent(2, "Choosing vowel based upon " preceding "." vowel "." following)
		
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
		this.LogEvent(2, "Transformed vowel selection to " series)
		
		
		if (! vowelStrokes.item(series)) {
			series := preceding . vowel 
			if (! vowelStrokes.item(series)) {
				series := vowel
				if (! vowelStrokes.item(series)) {
					this.LogEvent(1, "Need to create vowel stroke for """ series """")
				}
			}
		}
		
		Return series
	}

	advanceNib(path) {
		this.LogEvent(4, "Advancing nib column-wise per " path)
		subPaths := StrSplit(path, StrSplit("c,l", ","))
		advance := 1
		Loop % subPaths.MaxIndex() {
			subPath := subPaths[A_Index]
			FoundPosVar := RegExMatch(subPath, "O)(-?\d+),-?\d+ ?$" , subPathMatches)
			deltaX := Abs(subPathMatches[1] + 0)
			advance += deltaX
			this.LogEvent(3, "Advance nib " deltaX " pixels and total of " advance " for subpath " subpath)
		}
		this.LogEvent(3, "Total advance of nib " advance " pixels for path " path)
		Return advance
	}

	fillMissingCharacter() {
		Return "l 3,-3 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,6 l 3,-6 l 3,3"
	}

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("pad",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}