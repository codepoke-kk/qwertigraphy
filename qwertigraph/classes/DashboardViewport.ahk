; To Do
; Create a reusable bitmap for each qwerd
; partial - Refactor variables to wordText, qwerdText, qwerdForm, and penForm
; Allow user to turn on/off display of wordText, qwerdText, qwerdForm, and penForm
; Improve width calculation of qwerdBitmap
; Create hashmap of qwerdBitmaps
; Allow user to set the height/width of the dashboard
; Done - Colorize forms (red and blue)
; Done - Show the in-progress form at the far right every time (in white)
; Fix bug where first form of the day is not drawn 
; https://www.autohotkey.com/boards/viewtopic.php?t=25966


;#######################################################################

; This function is called every time the user clicks on the gui
; The PostMessage will act on the globally defined window handle 
dashboardhwnd1 := ""
OnMessage(0x201, "WM_LBUTTONDOWN")
WM_LBUTTONDOWN(wParam, lParam, msg, dashboardhwnd1) {
	PostMessage 0xA1, 2
}

;#######################################################################

Class DashboardViewport 
{
   qwerdQueue := {}
   interval := 500
   qwerds := []
   logQueue := new Queue("DashboardQueue")
   logVerbosity := 4
   speedKeyed := 0
   speedEnhanced := 0
   coachAheadQwerd := new DashboardEvent("g-r-e-t-/-s", "grets", "Greetings", "white")
   comingSoonKeys := ["", "o", "i", "u", "e", "a", "d", "t", "s", "g", "n", "r"]
   coachAheadHints := ""
   coachAheadHeight := 0 ; 100
   
   ; Properties for dashboard
   Show := (this.map.qenv.properties.DashboardShow) ? this.map.qenv.properties.DashboardShow : 1
   AutohideSeconds := (this.map.qenv.properties.DashboardAutohideSeconds) ? this.map.qenv.properties.DashboardAutohideSeconds : 30
   Width := 0
   Height := 0
   CornerRadius := 10
   BackGroundPen := ""
   BackGroundBrush := ""
   hwnd1 := ""
   hbm := ""
   hdc := ""
   obm := ""
   G := ""
   ;pBrush := ""
   ;pPen := ""
   ;pToken := ""
   
   ; Properties for writing
   QwerdColor := "cff000000"
   QwerdOptions := "x10 y10 w80 Left " this.QwerdColor " r4 s20 "
   FontName := "Arial"
   HintsFontName := "Consolas"
   TranscriptBackGroundColor := 0xffffffee
   CoachAheadBackGroundColor := 0xffeeffee
   IndicatorsBackGroundColor := 0xffeeeeff
   FormColor := 0xff000000
   FormColors := {"black": 0xff000000, "red": 0xffbb0000, "blue": 0xff0000bb, "green": 0xff00bb00, "olive": 0xff808000, "gold": 0xffcccc00, "white": 0xffffffff}
   FormPens := {}
   FormBrushes := {}
   FormWidth := 2
   SpeedColor := "cffff0000"
   SpeedPen := ""
   SpeedWidth := 6
   averageCharWidth := 11
   leftAnchor := 0
   topAnchor := 15
   qwerdSpacer := 9
   
   ; Properties for qwerd display
   ; The nib is where the next drawn point will land
   nibStart := {"x": this.dashwindow.width, "y": this.Height}
   lineHeight := {"wordtext": 2, "wordform": 24, "penform": 60, "qwerdtext": 92}
   nib := {"x": this.dashwindow.width, "y": this.Height}
   
   __New(qenv, engine)
   {
      global dashboardhwnd1 
      this.qenv := qenv
      this.logVerbosity := (this.qenv.properties.LoggingLevelDashboard) ? this.qenv.properties.LoggingLevelDashboard : 3
      this.Show := (this.qenv.properties.DashboardShow) ? this.qenv.properties.DashboardShow : 1
      this.AutohideSeconds := (this.qenv.properties.DashboardAutohideSeconds) ? this.qenv.properties.DashboardAutohideSeconds : 30
      this.engine := engine 
      this.dashboardQueue := engine.dashboardQueue
      this.auxKeyboardState := ""
      this.lastRefresh := A_TickCount
		
      this.timer := ObjBindMethod(this, "DequeueEvents")
      timer := this.timer
      SetTimer % timer, % this.interval
        
      ; Start gdi+
      If !this.pToken := Gdip_Startup()
      {
          MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
      }

      this.orientation := "vertical"
      this.DefineSizes()


      ; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
      Gui, DashboardGUI:New, -Caption +E0x80000 +LastFound +OwnDialogs, QDashboard
      Gui, DashboardGUI: Show, NA

      ; Get a handle to this window we have created in order to update it later
      this.hwnd1 := WinExist()
      ; dashboardhwnd1 := this.hwnd1
      ; HandleBitMap - Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
      this.hbm := CreateDIBSection(this.dashwindow.width, this.dashwindow.height)
      ; HandleDeviceContext - Get a device context compatible with the screen
      this.hdc := CreateCompatibleDC()
      ; ObjectBitMap - Select the bitmap into the device context
      this.obm := SelectObject(this.hdc, this.hbm)
      ; Graphics - Get a pointer to the graphics of the bitmap, for use with drawing functions
      this.G := Gdip_GraphicsFromHDC(this.hdc)
      ; Set the smoothing mode to antialias = 4 to make shapes appear smoother (only used for vector drawing and filling)
      Gdip_SetSmoothingMode(this.G, 4)
      ; (ARGB = Transparency, red, green, blue) to draw a rounded rectangle with

      this.TranscriptBackgroundBrush := Gdip_BrushCreateSolid(this.TranscriptBackgroundColor)
      this.CoachAheadBackgroundBrush := Gdip_BrushCreateSolid(this.CoachAheadBackgroundColor)
      this.IndicatorsBackgroundBrush := Gdip_BrushCreateSolid(this.IndicatorsBackgroundColor)
      ;this.BackgroundBrush := Gdip_BrushCreateSolid(this.BackgroundColor)
      ;this.BackgroundPen := Gdip_CreatePen(this.BackgroundColor, 3)

      ; (ARGB = Transparency, red, green, blue) of width 3 (the thickness the pen will draw at) to draw a circle
      For ink, value in this.FormColors 
      {
         this.LogEvent(4, "Creating pen and brush from " ink " as " value)
         FormPen := Gdip_CreatePen(value, this.FormWidth)
         this.FormPens[ink] := FormPen
         FormBrush := Gdip_BrushCreateSolid(value)
         this.FormBrushes[ink] := FormBrush
      }
      
      ; (ARGB = Transparency, red, green, blue) of width 3 (the thickness the pen will draw at) to draw a circle
      this.SpeedPen := Gdip_CreatePen(this.SpeedColor, this.SpeedWidth)


      ; Next we can check that the user actually has the font that we wish them to use
      ; If they do not then we can do something about it. I choose to give a wraning and exit!
      If !Gdip_FontFamilyCreate(this.FontName)
      {
          MsgBox "The font you have specified does not exist on the system"
          ExitApp
      }
      
      this.DrawBackground()
      
      this.LogEvent(2, "Dashboard initialized")
   }
   
   DefineSizes() {
      ; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
      
      SysGet, Mon1, MonitorWorkArea, 1
      this.workingwindow := {"left": Mon1Left, "right": Mon1Right, "top": Mon1Top, "bottom": Mon1Bottom}
      this.dashwindow := {}
      this.partnerwindow := {}
      this.cell := {} ; this will be the top left corner of each dashboard qwerd entry
      
      if (this.orientation == "vertical") {
         this.cell.height := 50
         this.dashwindow.width := 220
         this.dashwindow.left := Mon1Right - this.dashwindow.width
         this.dashwindow.right := Mon1Right
         this.dashwindow.top := Mon1Top
         this.dashwindow.bottom := Mon1Bottom
         this.dashwindow.height := Mon1Bottom - Mon1Top
         this.dashwindow.indicatorsTop := this.dashwindow.bottom - 100
         this.dashwindow.coachAheadTop := this.dashwindow.indicatorsTop - 280
         this.dashwindow.transcriptBottom := this.dashwindow.coachAheadTop
         this.partnerwindow := {"left": Mon1Left, "right": (Mon1Right - (this.dashwindow.width + 1)), "top": Mon1Top, "bottom": Mon1Bottom}
         this.partnerwindow.width := this.partnerwindow.right - this.partnerwindow.left
         this.partnerwindow.height := this.partnerwindow.bottom - this.partnerwindow.top
         this.cell.x := 0
         this.cell.y := 0
         this.cell.width := this.dashwindow.width
         this.cell.qwerd := {"x": 8, "y": 1}
         this.cell.word := {"x": 20, "y": 22}
         this.cell.form := {"x": -1, "y": -1}
         this.cell.penform := {"x": (this.cell.width - 20), "y": 20}
      } else {
         this.dashwindow.height := 200
         this.dashwindow.left := Mon1Left
         this.dashwindow.right := Mon1Right
         this.dashwindow.top := Mon1Top
         this.dashwindow.bottom := Mon1Top + this.dashwindow.height
         this.dashwindow.width := Mon1Right - Mon1Left
         this.partnerwindow := {"left": Mon1Left, "right": Mon1Right - (this.dashwindow.width + 1), "top": Mon1Top, "bottom": Mon1Bottom}
         this.cell.x := 0
         this.cell.y := 0
         this.cell.width := 200
         this.cell.height := this.dashwindow.height
         this.cell.word := {"x": 1, "y": 1}
         this.cell.qwerd := {"x": 20, "y": 20}
         this.cell.form := {"x": -1, "y": -1}
         this.cell.penform := {"x": (this.cell.width - 10), "y": 40}
      }
   }
   
   DrawBackground() {
      if (not this.Show) {
         Return 
      }
      
      this.LogEvent(4, "Height is " this.dashwindow.height)
      ; Gdip_GraphicsClear(this.G)
      
      ; Clear transcript area
      Gdip_FillRectangle(this.G, this.TranscriptBackgroundBrush, 0, 0, this.dashwindow.width, this.dashwindow.coachAheadTop)
      this.LogEvent(3, "Just erased " 0 " to " this.dashwindow.coachAheadTop)

      
      ; Draw pending hints
      Gdip_FillRectangle(this.G, this.CoachAheadBackgroundBrush, 0, this.dashwindow.coachAheadTop, this.dashwindow.width, this.dashwindow.indicatorsTop - this.dashwindow.coachAheadTop)
      this.LogEvent(3, "Just erased " this.dashwindow.coachAheadTop " to " (this.dashwindow.indicatorsTop - this.dashwindow.coachAheadTop))
      HintOptions := "x10 y" (this.dashwindow.coachAheadTop + this.cell.height) " Left " this.FormColors["white"] " r4 s16 "
      this.LogEvent(3, "Drawing coachahead as " HintOptions)
      Gdip_TextToGraphics(this.G, this.coachAheadNote, HintOptions, this.HintsFontName, this.dashwindow.width, this.dashwindow.height)
      
      ; Draw WPM Meter
      Gdip_FillRectangle(this.G, this.IndicatorsBackgroundBrush, 0, this.dashwindow.indicatorsTop, this.dashwindow.width, this.dashwindow.height - this.dashwindow.indicatorsTop)
      this.LogEvent(3, "Just erased " this.dashwindow.indicatorsTop " to " (this.dashwindow.height - this.dashwindow.indicatorsTop))
      EnhancedSpeedOptions := "x20 y" this.dashwindow.indicatorsTop " Left " this.SpeedColor " r4 s32 "
      this.LogEvent(1, "Drawing enhanced speed " EnhancedSpeedOptions " as " this.speedEnhanced)
      Gdip_TextToGraphics(this.G, (this.speedEnhanced . " wpm"), EnhancedSpeedOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      KeyedSpeedOptions := "x20 y" (this.dashwindow.indicatorsTop + 35)  " Left " this.SpeedColor " r4 s28 "
      this.LogEvent(1, "Drawing keyed speed " KeyedSpeedOptions " as " this.speedKeyed)
      Gdip_TextToGraphics(this.G, (this.speedKeyed . " wpm"), KeyedSpeedOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      
      ; Draw Aux Keyboard status
      AuxKeyboardOptions := "x20 y" (this.dashwindow.indicatorsTop + 70)  " Left " this.SpeedColor " r4 s16 "
      this.LogEvent(4, "Drawing aux keyboard state " this.auxKeyboardState " as " AuxKeyboardOptions)
      Gdip_TextToGraphics(this.G, this.auxKeyboardState, AuxKeyboardOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }
   
   BackstepCell() {
      if (this.orientation == "vertical") {
         this.cell.y -= this.cell.height
      } else {
         this.cell.x -= this.cell.width
      }
   }
   
   visualizeQueue() {
      ; Walk queue of qwerds from last back, drawing each qwerd as we go from right side of dashboard to left
      local
      if (not this.Show) {
         Return 
      }
      
      
      ;if ((this.lastRefresh + 1000) < A_TickCount) {
         this.LogEvent(4, "Aborting refresh at " A_TickCount " since " this.lastRefresh)
         ;return
      ;}
      this.lastRefresh := A_TickCount
      
      this.DrawBackground()
      ; Set the nib start points
      
      if (this.orientation == "vertical") {
         this.cell.x := 0
         this.cell.y := this.dashwindow.transcriptBottom
      } else {
         this.cell.x := this.dashwindow.right
         this.cell.y := 0
      }
      this.LogEvent(2, "Starting visualization at " this.cell.x "," this.cell.y)
      ;this.BackstepCell()
      
      ;this.LogEvent(2, "Visualizing coachahead qwerd " this.coachAheadQwerd.qwerd " at " ;this.cell.x "," this.cell.y)
      ;this.DrawQwerd(this.coachAheadQwerd)
      
      this.BackstepCell()
      this.LogEvent(3, "Visualizing " this.qwerds.MaxIndex() " events starting at " this.cell.x "," this.cell.y)
      
      queueIndex := this.qwerds.MaxIndex()
      Loop, % this.qwerds.MaxIndex() + 1
      {
         this.LogEvent(2, "Visualizing " queueIndex " as " this.qwerds[queueIndex].form " at " this.cell.x "," this.cell.y)
         this.DrawQwerd(this.qwerds[queueIndex])
         this.BackstepCell()
         queueIndex--
         if ((this.cell.x < -100) or (this.cell.y < -100)) {
            this.LogEvent(3, "Dashboard full with " queueIndex " words remaining")
            break
         }
      }
      
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }
   
   DrawQwerd(qwerd) {
      local
      qwerd := this.qenv.redactSenstiveQwerd(qwerd)
      this.LogEvent(2, "Drawing " qwerd.word "/" qwerd.form "/" qwerd.qwerd " in ink " qwerd.ink " at " this.cell.x "," this.cell.y)
      ; testgray := Gdip_BrushCreateSolid(0x99999999)
      ; Gdip_FillRectangle(this.G, testgray, 0, 200, 5, this.cell.height)
      if ((qwerd.ink == "blue") and (qwerd.chorded)) {
        qwerd.ink := "gold"
      }
      if ((qwerd.ink == "red") and (qwerd.qwerd == "")) {
        qwerd.ink := "olive"
      }
      if ((qwerd.ink == "red") and (StrLen(qwerd.qwerd) >= StrLen(qwerd.word))) {
        qwerd.ink := "olive"
      }
      Gdip_FillRectangle(this.G, this.FormBrushes[qwerd.ink], this.cell.x + 2, this.cell.y, 7, this.cell.height)
      this.DrawWordText(qwerd.word)
      ; this.DrawQwerdForm(qwerd.form)
      this.DrawPenForm(qwerd.form, qwerd.ink)
      this.DrawQwerdText(qwerd.qwerd "/" qwerd.form)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }

   DrawWordText(text) {
      local
      if (this.cell.word.x < 0) {
         return
      }
      QwerdOptions := "x" (this.cell.x + this.cell.word.x) " y" (this.cell.y + this.cell.word.y) " Left " this.QwerdColor " r4 s20 "
      this.LogEvent(4, "Drawing as " QwerdOptions)
      Gdip_TextToGraphics(this.G, text, QwerdOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }

   DrawQwerdForm(text) {
      local
      if (this.cell.form.x < 0) {
         return
      }
      QwerdOptions := "x" (this.cell.x + this.cell.form.x) " y" (this.cell.y + this.cell.form.y) " Left " this.QwerdColor " r4 s20 "
      this.LogEvent(4, "Drawing as " QwerdOptions)
      Gdip_TextToGraphics(this.G, text, QwerdOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }

   DrawQwerdText(text) {
      local
      if (this.cell.qwerd.x < 0) {
         return
      }
      QwerdOptions := "x" (this.cell.x + this.cell.qwerd.x) " y" (this.cell.y + this.cell.qwerd.y) " Left " this.QwerdColor " r4 s20 "
      this.LogEvent(4, "Drawing as " QwerdOptions)
      Gdip_TextToGraphics(this.G, text, QwerdOptions, this.FontName, this.dashwindow.width, this.dashwindow.height)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }
   
   DrawPenForm(form, ink) {
      local
      if (this.cell.penform.x < 0) {
         return
      }
      subpaths := this.GetSubPaths(form)
      qwerdWidth := this.GetWidthOfQwerd(form)
      nib := {"x": (this.cell.x + this.cell.penform.x - qwerdWidth), "y": (this.cell.y + this.cell.penform.y)}
      this.LogEvent(3, "nib will start at " nib.x "," nib.y " after qwerdWidth of " qwerdWidth)
      if (this.FormPens[ink]) {
         formPen := this.FormPens[ink]
      } else {
         formPen := this.FormPens["black"]
      }
      for spindex, subpath in subpaths { 
         this.LogEvent(3, "Drawing subpath " subpath)
         this.LogEvent(3, "Stroke will be " subpath)
         strokeCoordinates := StrSplit(subpath, " ")
         this.LogEvent(3, "Stroke type is " strokeCoordinates[1])
         if (strokeCoordinates[1] == "c") {
            p1 := this.CoordinateToPoint(strokeCoordinates[2])
            p2 := this.CoordinateToPoint(strokeCoordinates[3])
            end := this.CoordinateToPoint(strokeCoordinates[4])
            this.LogEvent(4, "Drawing bezier " nib.x "," nib.y " " nib.x+p1.x "," nib.y+p1.y " " nib.x+p2.x "," nib.y+p2.y " " nib.x+end.x "," nib.y+end.y)
            Gdip_DrawBezier(this.G, formPen, nib.x, nib.y, nib.x+p1.x, nib.y+p1.y, nib.x+p2.x, nib.y+p2.y, nib.x+end.x, nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else if (strokeCoordinates[1] == "l") {
            end := this.CoordinateToPoint(strokeCoordinates[2])
            this.LogEvent(4, "Drawing line " nib.x "," nib.y " " nib.x+end.x "," nib.y+end.y)
            Gdip_DrawLine(this.G, formPen, nib.x, nib.y, nib.x+end.x, nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else if (strokeCoordinates[1] == "m") {
            end := this.CoordinateToPoint(strokeCoordinates[2])
            this.LogEvent(4, "Skipping along line " nib.x "," nib.y " " nib.x+end.x "," nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else {
            this.LogEvent(2, "Don't understand form " form ", subpath " subpath)
         }
      }
   }
	GetSubPaths(form) {  
		local
		this.LogEvent(4, "Getting subpaths for " form)
		subpaths := []
		elements := StrSplit(form, "-")
		for index, element in elements {
			this.LogEvent(4, "Element " A_Index " = " element)
		}
		startIndex := 0
		endIndex := elements.MaxIndex()
		; Crawl elements looking for the longest element we can match from the left side anchor of the form
		; As we match elements, start again from the left-most unmatched element until all are done 
		stopper := 0
		While (startIndex < endIndex) {
			this.LogEvent(4, "While loop starting at " startIndex " working toward " endIndex)
			; Loop enough times to see every possible match - break on first (longest) match
            matchDetector := 0
			Loop, % (endIndex - startIndex) {
				elementsInMatch := endIndex - startIndex - (A_Index - 1) 
				this.LogEvent(4, "Seeking largest left-anchored match iteration using " elementsInMatch " elements")
				candidateForm := ""
				Loop, % elementsInMatch {
					this.LogEvent(4, "Building candidate form adding " elements[A_Index + startIndex] "-")
				    candidateForm .= elements[A_Index + startIndex] "-"
				}
				candidateForm := SubStr(candidateForm, 1, StrLen(candidateForm) - 1)
				this.LogEvent(4, "Candidate form " candidateForm)
				if (this.qenv.strokepaths.item(candidateForm).path) {
					this.LogEvent(4, "Pushing " this.qenv.strokepaths.item(candidateForm).path " onto array with " subpaths.MaxIndex() " elements")
					subpaths := this.GetSubPathStrokes(subpaths, this.qenv.strokepaths.item(candidateForm).path)
					this.LogEvent(4, "Incrementing startIndex by number of elements matched " elementsInMatch)
					startIndex += elementsInMatch
                    matchDetector := 1
					break
				} else {
					this.LogEvent(4, "No match")
				}
			}
            if (! matchDetector) {
               ; We went through the whole list of strokes and found no matches 
				this.LogEvent(3, "No matches were detected in GetSubPaths for " form)
                break
            }
			stopper++
			if (stopper > 20) {
				this.LogEvent(1, "Infinite loop catchers says there were too many iterations in GetSubPaths for " form)
				break
			}
		}
		return subpaths
	}
	
	GetSubPathStrokes(outArray, subPaths) {
		local
		this.LogEvent(4, "Splitting " subPaths " into strokes")
		subPathStroke := ""
		elements := StrSplit(subPaths, " ")
		for index, element in elements {
			if (InStr("lmc", element)) {
				if (subPathStroke) {
					this.LogEvent(3, "Adding " subPathStroke " into array")
					outArray.Push(subPathStroke)
				}
				subPathStroke := element " "
			} else {
				subPathStroke .= element " "
			}
		}
		if (subPathStroke) {
			this.LogEvent(4, "Adding " subPathStroke " into array")
			outArray.Push(subPathStroke)
		}
		this.LogEvent(4, "Returning array with " outArray.MaxIndex() " elements")
		Return outArray
	}

   
   GetWidthOfQwerd(form) {
      local
      width := this.GetWidthOfQwerdForm(form)
      this.LogEvent(3, "Qwerd width is " width)
      Return width
   }
   
   GetWidthOfQwerdText(text) {
      local
      this.LogEvent(4, "Getting qwerd width of " text)
      Return (StrLen(text) * this.averageCharWidth) + this.qwerdSpacer
   }
   
   GetWidthOfQwerdForm(form) {
      local
      this.LogEvent(4, "Getting form width of " form)
      formStrokes := StrSplit(form, "-")
      width := this.qwerdSpacer
      for fsindex, formStroke in formStrokes { 
         this.LogEvent(4, "Working formStroke " formStroke)
         strokePath := this.GetStrokePath(formStroke)
         this.LogEvent(4, "Stroke will be " strokePath)
         strokeCoordinates := StrSplit(strokePath, " ")
         this.LogEvent(4, "Stroke type is " strokeCoordinates[1])
         if (strokeCoordinates[1] == "c") {
            point := this.CoordinateToPoint(strokeCoordinates[4])
         } else if ((strokeCoordinates[1] == "l") or (strokeCoordinates[1] == "m")) {
            point := this.CoordinateToPoint(strokeCoordinates[2])
         } else {
            point := this.CoordinateToPoint("11,11")
         }
         width += point.x
      }
      this.LogEvent(4, "Form width is " width)
      Return width
   }
   
   GetStrokePath(stroke) {
      global strokes
      global vowelStrokes
      this.LogEvent(3, "Getting width of " stroke)
      if (this.qenv.strokepaths.item(stroke)) {
         Return this.qenv.strokepaths.item(stroke).path
      ;} else if (vowelStrokes.item(stroke)) {
      ;   Return vowelStrokes.item(stroke)
      } else {
         Return "l 20,0"
      }  
   }
   
   CoordinateToPoint(coord) {
      local
      dims := StrSplit(coord, ",")
      Return {"x": dims[1] + 0, "y": dims[2] + 0}
   }
   
   ShowHide() {
      if (this.Show) {
         Gui, DashboardGUI: Show, NA
      } else {
         Gui, DashboardGUI: Show, Hide
      }
   }
   
   SetPendingQwerd(qwerd) {
   }
	
   DequeueEvents() {
      local 
      global DashboardEvent
      this.LogEvent(4, "Dequeueing dashboard events for " this.dashboardQueue.getSize())
      foundCount := 0
      Loop, % this.dashboardQueue.getSize() {
         qwerd := this.dashboardQueue.dequeue()
         this.LogEvent(3, "Dequeued event for " qwerd.form)
         this.qwerds.Push(qwerd)
         foundCount++
      }
      ; If we got an event, visualize it 
      if (foundCount) {
         this.coachAheadQwerd := new DashboardEvent("--", "", "--", "white")
         this.visualizeQueue()
      }
      this.ComingSoon()
   }
   
   ComingSoon() {
        if ((not this.engine.keyboard.Token) or (InStr("0123456789", SubStr(this.engine.keyboard.Token,1,1)))) {
           Return 
        }
        this.LogEvent(4, "Coming soon " this.engine.keyboard.Token)
        this.coachAheadNote := this.engine.keyboard.Token
        For letter_index, letter in this.comingSoonKeys {
           if (this.engine.map.qwerds.item(this.engine.keyboard.Token . letter).word) {
                coachAheadPhrase := Format("{:2} {:1}= {:-20}", letter, this.engine.map.qwerds.item(this.engine.keyboard.Token . letter).reliability, this.engine.map.qwerds.item(this.engine.keyboard.Token . letter).word)
            } else {
                coachAheadPhrase := Format("{:2} {:1}= {:-20}", letter, " ", "")
            }
            this.logEvent(4, "Adding phrase to coaching " coachAheadPhrase)
            this.coachAheadNote .= coachAheadPhrase "`n"
        }
        this.logEvent(4, "Coaching note: " this.coachAheadNote)

        Gdip_FillRectangle(this.G, this.CoachAheadBackgroundBrush, 0, this.dashwindow.coachAheadTop, this.dashwindow.width, this.dashwindow.indicatorsTop - this.dashwindow.coachAheadTop)
        this.LogEvent(3, "Just erased " this.dashwindow.coachAheadTop " to " (this.dashwindow.indicatorsTop - this.dashwindow.coachAheadTop))
        
        if (this.orientation == "vertical") {
         this.cell.x := 0
         this.cell.y := this.dashwindow.coachAheadTop
        } else {
         this.cell.x := this.dashwindow.right
         this.cell.y := 0
        }

        this.LogEvent(2, "Visualizing coachahead qwerd " this.coachAheadQwerd.qwerd " at " this.cell.x "," this.cell.y)
        this.DrawQwerd(this.coachAheadQwerd)

        ; Draw pending hints
        HintOptions := "x10 y" (this.dashwindow.coachAheadTop + this.cell.height) " Left " this.FormColors["white"] " r4 s16 "
        this.LogEvent(3, "Drawing coachahead as " HintOptions)
        Gdip_TextToGraphics(this.G, this.coachAheadNote, HintOptions, this.HintsFontName, this.dashwindow.width, this.dashwindow.height)

        UpdateLayeredWindow(this.hwnd1, this.hdc, this.dashwindow.left, this.dashwindow.top, this.dashwindow.width, this.dashwindow.height)
   }
   
   ExposeDashboard(location) {
      this.LogEvent(3, "Exposing dashboard to the " location " against " this.dashwindow.left "," this.dashwindow.top "/" this.dashwindow.width "," this.dashwindow.height)
      SysGet, Mon1, MonitorWorkArea, 1
      ;dashwindow := {"left": Mon1Right - 220, "right": Mon1Right, "top": Mon1Top, "bottom": Mon1Bottom}
      ;partnerwindow := {"left": Mon1Left, "right": (Mon1Right - 221), "top": Mon1Top, "bottom": Mon1Bottom, "width": (Mon1Right - 221) - (Mon1Left), "height": Mon1Bottom - Mon1Top}
      windowIgnoreList := {"": true, "QDashboard": true, "Shell_TrayWnd": true}

      active_id := Winexist("A")
      qdash_id := Winexist("QDashboard")

      WinGet, id, List,,, Program Manager
      Loop, %id%
      {
          this_id := id%A_Index%
          WinGetClass, this_class, ahk_id %this_id%
          WinGetTitle, this_title, ahk_id %this_id%
          WinGetPos, appL, appT, appW, appH, %this_title% ; %this_id%
          WinActivate, ahk_id %this_id%

          if ((windowIgnoreList[this_class]) or (windowIgnoreList[this_title])) {
              ; Ignore all named windows 
              this.LogEvent(3, "Ignoring ahk_class " this_class ", " this_title " At " appL "," appT "/" appW "," appH)
              ; IfMsgBox, NO, break
          } else if ((appL > Mon1Right) or (appL + appW < Mon1Left) or (appT > Mon1Bottom) or (appT + appH < Mon1Top)) {
              this.LogEvent(3, "Leaving invisible ahk_class " this_class ", " this_title " At " appL "," appT "/" appW "," appH)
              ; Ignore windows the Windows system hides off the screen
          } else {
              this.LogEvent(3, "Evaluating ahk_class " this_class ", " this_title " At " appL "," appT "/" appW "," appH)
              if (appL + appW > this.dashwindow.left) {
                  ww := this.partnerwindow.width > appW ? appW : this.partnerwindow.width
                  wh := this.partnerwindow.height > appH ? appH : this.partnerwindow.height
                  wl := appL + ww <= this.partnerwindow.right ? appL : this.partnerwindow.right - ww
                  wt := appT + wh <= this.partnerwindow.bottom ? appT : this.partnerwindow.bottom - wh
                  this.LogEvent(3, "Moving ahk_class " this_class ", " this_title " to " wl "," wt "/" ww "," wh)
                  WinMove, %this_title%, , %wl%, %wt%, %ww%, %wh% 
              }
          }
      }

      Winactivate, ahk_id %qdash_id%
      Winactivate, ahk_id %active_id%

   }

   LogEvent(verbosity, message) 
   {
      if (verbosity <= this.logVerbosity) 
      {
         event := new LoggingEvent("dashboard",A_Now,message,verbosity)
         this.logQueue.enqueue(event)
      }
   }

}