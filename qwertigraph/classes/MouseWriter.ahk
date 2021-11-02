#SingleInstance,Force
coordmode, mouse, screen
#include MouseDelta.ahk
#include WriterMark.ahk
#include PenFormDecoder.ahk
#Include Gdip_All.ahk
#Include Queue.ahk
 
Gui, WriterGuiLog:Add, ListBox, w500 h200 hwndhOutput
Gui, WriterGuiLog:Add, Text, xm w500 center, Hit F12 to toggle on / off
Gui, WriterGuiLog:Show, x1000 y200, Mouse Watcher


Gui, WriterGuiPad: -Caption +E0x80000  +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs 
Gui, WriterGuiPad: Show, NA
writerhwnd := WinExist() ; hwnd7 to avoid conflict ("hwnd1" name is too much used in other scripts)

pi := 4 * ATan(1)
halfpi := 2 * ATan(1)
 
mouseDelta := new MouseDelta("MouseEvent")
writer := New MouseWriter(mouseDelta, writerhwnd, hOutput)
 
return
 
GuiClose:
	mouseDelta.Delete()
	mouseDelta := ""
	ExitApp

+^#F22::
F12::
	;writer.enabled := !writer.enabled
	writer.TogglePage()
	mouseDelta.SetState(writer.enabled)
	return
 
; Gets called when mouse moves
; x and y are DELTA moves (Amount moved since last message), NOT coordinates.
MouseEvent(MouseID, dx := 0, dy := 0){
	global writer
	global hOutput
	static text := ""
	static LastTime := 0
 
	if (GetKeyState("LButton", "P")) {
		t := A_TickCount
		MouseGetPos, mouseX, mouseY, mouseWin, mouseControl
		dt := LastTime ? t - LastTime : 0
		mark := New WriterMark(mouseX, mouseY, dx, dy, dt, t)
		writer.EnqueueMark(mark)
	} else {
		writer.lastMark := 0
		writer.waiting := true
	}
	; writer.DrawMarks()
	; GuiControl, , % hOutput, % "Adding new mark"
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	LastTime := t
}

Class MouseWriter {
	; a line segment showing whatever was last input by the mouse having moved 
	marks := []
	; a collection of marks making up a complete and distinct portion of a full outline - a stroke
	segments := []
	
	__New(mouseDelta, writerhwnd, writeroutput) {
		this.enabled := false
		this.decoder := New PenFormDecoder(writeroutput)
		this.markQueue := new Queue("MarkQueue")
		this.mouseDelta := mouseDelta
		this.writerhwnd := writerhwnd
		this.writeroutput := writeroutput
		this.Width := A_ScreenWidth, this.Height := A_ScreenHeight
		
		this.state := "waiting"  
		; 
		this.baseMark := 0
		this.lastMark := 0
		; define the size of the current penform as it's written 
		this.eastMark := 0
		this.southMark := 0
		this.westMark := 0
		this.northMark := 0
		this.xrange := 0
		this.yrange := 0
		this.xmidrange := 0
		this.ymidrange := 0
		
		
		If !this.pToken := Gdip_Startup()
		{
			MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
			ExitApp
		}
		
		;; Default objects are to the screen itself 
		; Handle to the BitMap
		this.hbm := CreateDIBSection(this.Width, this.Height)  ;screen
		; Handle the Device Context
		this.hdc := CreateCompatibleDC()             		   ;screen
		; Object for the Device Independent BitMap
		this.obm := SelectObject(this.hdc, this.hbm)           ;screen
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)


		;------------------------------------------------  create some brushes and pencils ------------------------------------
		this.pPen := Gdip_CreatePen("0xFF000000" , 3)  
		this.BackGroundColor := 0xccffffff
		this.BackgroundBrush := Gdip_BrushCreateSolid(this.BackgroundColor)    
		this.baseBrush := Gdip_BrushCreateSolid("0xff9999ff")
		this.baseBounds := {"minX": 500, "minY": 200, "maxX": 575, "maxY": 275, "width": 75, "height": 75}
		this.startBounds := {"minX": 580, "minY": 280, "maxX": 585, "maxY": 285, "width": 5, "height": 5}
        this.segmentPens := {}
		this.segmentPens["final"] := Gdip_CreatePen("0xff33ff33", 2)
		this.segmentPens["recurve"] := Gdip_CreatePen("0xffff3333", 2)
		this.segmentPens["discontinuity"] := Gdip_CreatePen("0xff3333ff", 2)
		this.segmentPens["intersection"] := Gdip_CreatePen("0xff33ffff", 2)
		this.segmentPens["disjoin"] := Gdip_CreatePen("0xffffff33", 2)
		
		scanInterval := 50
		this.scantimer := ObjBindMethod(this, "ScanInputs")
        scantimer := this.scantimer
		SetTimer % scantimer, % this.scanInterval

	}
	
	EnqueueMark(mark) {
		;GuiControl, , % this.writeroutput, % "Enqueuing new mark" 
		; Let's go strictly off deltas, and see how that works
		this.markQueue.enqueue(mark)
	}
	
	
	ScanInputs() {
		;GuiControl, , % this.writeroutput, % "Scanning for marks" 
		this.DequeueMarks()
		this.DetectSend()
	}
	
	DequeueMarks() {
		if (not this.enabled) {
			return
		}
		Loop, % this.markQueue.getSize() {
			mark := this.markQueue.dequeue()
			; Attempt smoothing
			;if ((!mark.dt) and ((mark.x = this.marks[this.marks.MaxIndex()].x) and (mark.y = this.marks[this.marks.MaxIndex()].y))) {
			if (this.lastMark) {
				mark.x := this.lastMark.x + mark.dx
				mark.y := this.lastMark.y + mark.dy
			}
			this.AddMark(mark)
		}
		;GuiControl, , % this.writeroutput, % "Dequeued marks" 
		UpdateLayeredWindow(this.writerhwnd, this.hdc, 0, 0, this.Width, this.Height)
	}
	
	AddMark(mark) { 
		Gui WriterGuiLog:Default
		;GuiControl, , % this.writeroutput, % "Adding mark" 
		if (this.lastMark) {
			;GuiControl, , % this.writeroutput, % "Wrote new mark" 
			Gdip_DrawLine(this.G, this.pPen, this.lastMark.x, this.lastMark.y, mark.x, mark.y)
		} 
		this.DetectStart(mark)
		this.marks.Push(mark)
		this.lastMark := mark
	}
	
	DetectStart(mark) {
		if (this.waiting) {
			if (this.isAtHomeBase(mark)) {
				; We are waiting and clicking and in the home base. Start
				GuiControl, , % this.writeroutput, % "Starting" 
				this.RefreshPage()
				this.waiting := false 
			}
		} 
	}
	
	DetectSend() {
		if ((not this.waiting) and (not GetKeyState("LButton", "P"))) {
			GuiControl, , % this.writeroutput, % "Sending" 
			this.SendPenform()
			this.waiting := true
		}
	}
	
	isAtHomeBase(mark) {
		return (mark.x > this.baseBounds.minX) and (mark.x < this.baseBounds.maxX) and (mark.y > this.baseBounds.minY) and (mark.y < this.baseBounds.maxY)
	}
	
	TogglePage() {
		GuiControl, , % this.writeroutput, % "Toggling from " this.enabled  
		if (this.enabled) {
			this.HidePage()
			this.enabled := false
		} else {
			this.RefreshPage()
			this.enabled := true
		}
	}
	
	RefreshPage() {
		GuiControl, , % this.writeroutput, % "Refresh page" 
		Gdip_GraphicsClear(this.G)  ;This sets the entire area of the graphics to 'transparent'
        Gdip_FillRectangle(this.G, this.BackgroundBrush, 0, 0, this.Width, this.Height)
		Gdip_FillRectangle(this.G, this.baseBrush, this.baseBounds.minX, this.baseBounds.minY, this.baseBounds.width, this.baseBounds.height)
		UpdateLayeredWindow(this.writerhwnd, this.hdc, 0, 0, this.Width, this.Height)  ;This is what actually changes the display
	}
	
	HidePage() {
		GuiControl, , % this.writeroutput, % "Hide Page"
		Gdip_GraphicsClear(this.G)  ;This sets the entire area of the graphics to 'transparent'
		UpdateLayeredWindow(this.writerhwnd, this.hdc, 0, 0, this.Width, this.Height)  ;This is what actually changes the display
	}
	
	SendPenform() {
		GuiControl, , % this.writeroutput, % "Sending " this.marks.MaxIndex() " penform marks" 
		segments := this.decoder.DecodePenForm(this.marks)
		for index, segment in segments 
		{
			GuiControl, , % this.writeroutput, % "Drawing " segment.type " at " this.marks[segment.endindex].x "," this.marks[segment.endindex].y
			Gdip_DrawEllipse(this.G, this.segmentPens[segment.type], this.marks[segment.endindex].x - 5, this.marks[segment.endindex].y - 5, 10, 10)
		}
		
		FileDelete, "marks.csv"
		fileHandle := FileOpen("marks.csv", "w")
		header := "x,y,dx,dy,dt,t`n"
		fileHandle.Write(header)
		for index, mark in this.marks 
		{
			fileHandle.Write(mark.Serialize() "`n")
		}
		filehandle.Close()
		
		this.marks := []
		
	}
}