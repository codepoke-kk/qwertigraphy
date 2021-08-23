
global strokes := ComObjCreate("Scripting.Dictionary")
global vowelStrokes := ComObjCreate("Scripting.Dictionary")
#Include classes\strokes.ahk

Class DashboardViewport 
{
   qwerdQueue := {}
   interval := 500
   qwerds := []
   logQueue := new Queue("DashboardQueue")
   logVerbosity := 2
   speedKeyed := 0
   speedEnhanced := 0
   
   ; Properties for dashboard
   Show := (this.map.qenv.properties.DashboardShow) ? this.map.qenv.properties.DashboardShow : 1
   AutohideSeconds := (this.map.qenv.properties.DashboardAutohideSeconds) ? this.map.qenv.properties.DashboardAutohideSeconds : 30
   Width := 600
   Height := 105
   CornerRadius := 10
   BackGroundColor := 0x22000000
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
   QwerdColor := "c88000000"
   QwerdOptions := "x10 y10 w80 Left " this.QwerdColor " r4 s20 "
   FontName := "Arial"
   FormColor := 0x88000000
   FormPen := ""
   FormWidth := 2
   SpeedColor := "c88ff0000"
   SpeedPen := ""
   SpeedWidth := 6
   averageCharWidth := 14
   leftAnchor := 0
   topAnchor := 0
   qwerdSpacer := 5
   
   ; Properties for qwerd display
   ; The nib is where the next drawn point will land
   nibStart := {"x": this.Width, "y": this.Height}
   lineHeight := {"text": 5, "form": 60}
   nib := {"x": this.Width, "y": this.Height}
   
   __New(qenv, dashboardQueue)
   {
      this.qenv := qenv
      this.logVerbosity := (this.qenv.properties.LoggingLevelDashboard) ? this.qenv.properties.LoggingLevelDashboard : 3
      this.Show := (this.qenv.properties.DashboardShow) ? this.qenv.properties.DashboardShow : 1
      this.AutohideSeconds := (this.qenv.properties.DashboardAutohideSeconds) ? this.qenv.properties.DashboardAutohideSeconds : 30
      this.dashboardQueue := dashboardQueue
		
      this.timer := ObjBindMethod(this, "DequeueEvents")
      timer := this.timer
      SetTimer % timer, % this.interval
      
      this.LogEvent(4, "Creating Autohide Timer")
      this.autoHidetimer := ObjBindMethod(this, "AutohideDashboard")
      autoHidetimer := this.autoHidetimer
      SetTimer % autoHidetimer, % (this.AutohideSeconds * 1000)
        
      ; Start gdi+
      If !this.pToken := Gdip_Startup()
      {
          MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
      }

      ; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
      this.Width := 600
      this.Height := 105
      SysGet, workingScreen, MonitorWorkArea, 1
      this.leftAnchor := workingScreenLeft + (((workingScreenRight - workingScreenLeft)/2) - (this.Width/2))

      ; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
      Gui, DashboardGUI: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
      Gui, DashboardGUI: Show, NA

      ; Get a handle to this window we have created in order to update it later
      this.hwnd1 := WinExist()
      ; HandleBitMap - Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
      this.hbm := CreateDIBSection(this.Width, this.Height)
      ; HandleDeviceContext - Get a device context compatible with the screen
      this.hdc := CreateCompatibleDC()
      ; ObjectBitMap - Select the bitmap into the device context
      this.obm := SelectObject(this.hdc, this.hbm)
      ; Graphics - Get a pointer to the graphics of the bitmap, for use with drawing functions
      this.G := Gdip_GraphicsFromHDC(this.hdc)
      ; Set the smoothing mode to antialias = 4 to make shapes appear smoother (only used for vector drawing and filling)
      Gdip_SetSmoothingMode(this.G, 4)
      ; (ARGB = Transparency, red, green, blue) to draw a rounded rectangle with
      this.BackgroundBrush := Gdip_BrushCreateSolid(this.BackgroundColor)
      this.BackgroundPen := Gdip_CreatePen(this.BackgroundColor, 3)

      ; (ARGB = Transparency, red, green, blue) of width 3 (the thickness the pen will draw at) to draw a circle
      this.FormPen := Gdip_CreatePen(this.FormColor, this.FormWidth)
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
      this.DrawForm("playing")
      this.DrawText("plag")
      
      this.LogEvent(2, "Dashboard initialized")
   }
   
   DrawBackground() {
      Gdip_GraphicsClear(this.G)
      Gdip_FillRoundedRectangle(this.G, this.BackgroundBrush, 0, 0, this.Width, this.Height, this.CornerRadius)
      
      EnhancedSpeedOptions := "x20 y20 Left " this.SpeedColor " r4 s36 "
      this.LogEvent(4, "Drawing enhanced speed " EnhancedSpeedOptions)
      Gdip_TextToGraphics(this.G, this.speedEnhanced, EnhancedSpeedOptions, this.FontName, this.Width, this.Height)
      KeyedSpeedOptions := "x20 y60 Left " this.SpeedColor " r4 s36 "
      this.LogEvent(4, "Drawing keyed speed " KeyedSpeedOptions)
      Gdip_TextToGraphics(this.G, this.speedKeyed, KeyedSpeedOptions, this.FontName, this.Width, this.Height)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.leftAnchor, this.topAnchor, this.Width, this.Height)
   }
   
   visualizeQueue() {
      ; Walk queue of qwerds from last back, drawing each qwerd as we go from right side of dashboard to left
      local
      ; We saw a new qwerd, so reset the autohide timer
      
      this.LogEvent(4, "Setting Autohide Timer")
      timer := this.autoHidetimer
      SetTimer % timer, % (this.AutohideSeconds * 1000)
      Gui, DashboardGUI: Show, NA
      
      this.DrawBackground()
      ; Set the nib start points
      this.nibStart := {"x": this.Width, "y": this.Height}
      
      this.LogEvent(3, "Visualizing " this.qwerds.MaxIndex() " events at " this.nibStart.x "," this.nibStart.y)
      queueIndex := this.qwerds.MaxIndex()
      Loop, % this.qwerds.MaxIndex()
      {
         this.LogEvent(3, "Visualizing " queueIndex " as " this.qwerds[queueIndex].form " at " this.nibStart.x "," this.nibStart.y)
         this.DrawQwerd(this.qwerds[queueIndex])
         queueIndex--
         if (this.nibStart.x < -100) {
            this.LogEvent(3, "Dashboard full with " queueIndex " words remaining")
            break
         }
      }
   }
   
   DrawQwerd(qwerd) {
      local
      qwerdWidth := this.GetWidthOfQwerd(qwerd)
      this.nibStart.x -= qwerdWidth
      this.LogEvent(3, "Drawing " qwerd.form "/" qwerd.qwerd " at " this.nibStart.x "," this.lineHeight.text)
      ; Write the word when the qwerd is longer than it 
      ;drawText := StrLen(qwerd.qwerd) > StrLen(qwerd.word) ? qwerd.word : qwerd.qwerd
      drawText := StrLen(qwerd.form) > StrLen(qwerd.word) ? qwerd.word : qwerd.form
      this.DrawText(drawText)
      this.DrawForm(qwerd.form)
   }

   DrawText(text) {
      local
      QwerdOptions := "x" this.nibStart.x " y" this.lineHeight.text " Left " this.QwerdColor " r4 s20 "
      this.LogEvent(4, "Drawing as " QwerdOptions)
      Gdip_TextToGraphics(this.G, text, QwerdOptions, this.FontName, this.Width, this.Height)
      UpdateLayeredWindow(this.hwnd1, this.hdc, this.leftAnchor, this.topAnchor, this.Width, this.Height)
   }
   
   DrawForm(form) {
      local
      subpaths := this.GetSubPaths(form)
      nib := {"x": this.nibStart.x, "y": this.lineHeight.form}
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
            Gdip_DrawBezier(this.G, this.FormPen, nib.x, nib.y, nib.x+p1.x, nib.y+p1.y, nib.x+p2.x, nib.y+p2.y, nib.x+end.x, nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else if (strokeCoordinates[1] == "l") {
            end := this.CoordinateToPoint(strokeCoordinates[2])
            this.LogEvent(4, "Drawing line " nib.x "," nib.y " " nib.x+end.x "," nib.y+end.y)
            Gdip_DrawLine(this.G, this.FormPen, nib.x, nib.y, nib.x+end.x, nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else if (strokeCoordinates[1] == "m") {
            end := this.CoordinateToPoint(strokeCoordinates[2])
            this.LogEvent(4, "Skipping along line " nib.x "," nib.y " " nib.x+end.x "," nib.y+end.y)
            nib.x += end.x
            nib.y += end.y
         } else {
            this.LogEvent(1, "Don't understand form " form ", subpath " subpath)
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
					break
				} else {
					this.LogEvent(4, "No match")
				}
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

   
   GetWidthOfQwerd(qwerd) {
      local
      qwerdWidth := this.GetWidthOfQwerdText(qwerd.qwerd)
      formWidth := this.GetWidthOfQwerdForm(qwerd.form)
      width := qwerdWidth > formWidth ? qwerdWidth : formWidth
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
	
   DequeueEvents() {
      local 
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
         this.visualizeQueue()
      }
   }
   
   AutohideDashboard() {
      this.LogEvent(4, "Autohiding after " this.AutohideSeconds)
      Gui, DashboardGUI: Show, Hide
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