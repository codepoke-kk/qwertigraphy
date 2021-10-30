;#SingleInstance,Force

;Gui, DecoderGuiLog:Add, ListBox, w500 h200 hwnddecoderoutput
;Gui, DecoderGuiLog:Add, Text, xm w500 center, Just watching 
;Gui, DecoderGuiLog:Show, x1000 y200, Decoder Watcher
;GuiControl, , % decoderoutput, % "Building " decoderoutput

;decoder := New MouseDecoder(decoderoutput)

;return
 
;GuiClose:
;	ExitApp
	

Class PenFormDecoder {
	; The idea is to break an incoming pen form into separate segments
	; Each segment will be a continuous flow bending in a given direction 
	; When a left-hand bend turns into a right-hand bend, segment 
	; When a flow suddenly breaks into a whole new direction, segment
	; When the path intersects or is headed toward intersection and suddenly stops, segment twice 
	; When the path disjoins, segment and treat intersections as modifiers rather than double splits

	; a line segment showing whatever was last input by the mouse having moved 
	marks := []
	; a collection of marks making up a complete and distinct portion of a full outline - a stroke
	segments := []
	
	__New(decoderoutput) {
		this.pi := 4 * ATan(1)
		this.halfpi := 2 * ATan(1)
		this.quarterpi := ATan(1)
		this.eighthpi := ATan(1) / 2
		this.decoderoutput := decoderoutput
		this.lastMark := 0
		
		GuiControl, , % this.decoderoutput, % "Loaded decoder"
		; this.AugmentMarks()
		; this.SegmentPenForm()
	}
	
	DecodePenForm(marks) {
		this.marks := marks
		GuiControl, , % this.decoderoutput, % "Received " this.marks.MaxIndex() " marks"
		this.AugmentMarks()
		this.SegmentPenForm()
	}
	
	AugmentMarks() {
		for index, mark in this.marks 
		{
			if (this.lastMark) {
				lastMarkRads := this.GetRads(mark.x - this.lastMark.x, mark.y - this.lastMark.y)
			} else {
				lastMarkRads := 0
			}
			introspectRads := this.GetRads(mark.dx, mark.dy)
			mark.rads := lastMarkRads ? lastMarkRads : introspectRads
			;GuiControl, , % this.decoderoutput, % "Radss for " index ": " mark.Rads
			this.lastMark := mark
		}
	}
	
	SegmentPenForm() {
		segmentMarks := []
		for index, mark in this.marks 
		{
			if (this.DetectNewSegment(segmentMarks)) {
				segment := this.GetSegment(segmentMarks) 
				this.segments.Push(segment)
				segmentMarks := []
				GuiControl, , % this.decoderoutput, % "New segment " segment.length "@" segment.rads " covering " segment.area
			}
			segmentMarks.Push(mark)
		}
		if (segmentMarks.MaxIndex()) {
			segment := this.GetSegment(segmentMarks) 
			this.segments.Push(segment)
			GuiControl, , % this.decoderoutput, % "Final segment " segment.length "@" segment.rads " covering " segment.area
		}
	}
	
	GetSegment(segmentMarks) {
		segment := {"marks": segmentMarks, "start": segmentMarks[1], "end": segmentMarks[segmentMarks.MaxIndex()]
			, "length": 0, "rads": 0, "apogeeIndex": 0, "height": 0, "area": 0}
		segment.length := this.GetLength(segment.start, segment.end)
		segment.rads := this.GetRads((segment.end.x - segment.start.x), (segment.end.y - segment.start.y))
		segment.apogeeIndex := this.GetApogeeIndex(segment)
		segment.height := this.GetHeight(segment)
		segment.area := this.GetArea(segment)
		;GuiControl, , % this.decoderoutput, % "New segment " segment.length "@" segment.rads " covering " segment.area
		Return segment 
	}
	
	DetectNewSegment(segmentMarks) {
		if (this.DetectNewCurve(segmentMarks)) {
			Return true
		} else if (this.DetectDiscontinuity(segmentMarks)) {
			Return true
		} else if (this.DetectIntersection(segmentMarks)) {
			Return true
		} else if (this.DetectDisjoin(segmentMarks)) {
			Return true
		} else {
			Return false
		}
	}
	
	DetectNewCurve(segmentMarks) {
		Return false 
	}
	DetectDiscontinuity(segmentMarks) {
		i := segmentMarks.MaxIndex()
		if ( i < 10) {
			Return false
		}
		trunkStart := segmentMarks[i-9]
		trunkEnd := segmentMarks[i-5]
		growthStart := segmentMarks[i-4]
		growthEnd := segmentMarks[i]
		trunkRads := this.GetRads(trunkEnd.x - trunkStart.x, trunkEnd.y - trunkStart.y)
		growthRads := this.GetRads(growthEnd.x - growthStart.x, growthEnd.y - growthStart.y)
		
		if (Abs(growthRads - trunkRads) > this.quarterpi) {
			GuiControl, , % this.decoderoutput, % "Discontinuity with " trunkRads " to " growthRads " at index " i
			Return true 
		}
	}
	DetectIntersection(segmentMarks) {
		Return false 
	}
	DetectDisjoin(segmentMarks) {
		Return false 
	}
	
	
	GetRads(dx,dy) {
		; There has got to be an easier wady, but I understand this and its output. 
		rads := 0
		if (dx = 0 or dy = 0) {
			if (dx = 0 and dy = 0) {
				rads := 0
			} else if (dx = 0 and dy > 0) {
				rads := this.halfpi
			} else if (dx = 0 and dy < 0) {
				rads := -this.halfpi
			} else if (dx > 0 and dy = 0) {
				rads := 0
			} else if (dx < 0 and dy = 0) {
				rads := this.pi
			}
		} else if (dx > 0 and dy < 0) {
			; Quadrant 1, -this.halfpi < rads < 0
			rads := ATan(dy/dx)
		} else if (dx > 0 and dy > 0) {
			; Quadrant 2, 0 < rads < this.halfpi
			rads := ATan(dy/dx)
		} else if (dx < 0 and dy > 0) {
			; Quadrant 3, this.halfpi < rads < this.pi
			rads := ATan(dy/dx) + this.pi
		} else if (dx < 0 and dy < 0) {
			; Quadrant 4, -this.pi < rads < -this.halfpi
			rads := ATan(dy/dx) - this.pi
		}
		Return rads 
	}
	
	GetLength(start, end) {
		Return Sqrt(((end.x - start.x) ** 2) + ((end.y - start.y) ** 2))
	}
	
	GetApogeeIndex(segment) {
		startMark := segment.marks[1]
		pinMark := segment.marks[3]
		pinRads := this.GetRads(pinMark.x - startMark.x, pinMark.y, startMark.y)
		;GuiControl, , % this.decoderoutput, % "Start Rads are " pinRads " and seeking " segment.rads 
		
		; If start angle is bigger than the segment's angle, then we want to find the index where the pinRads are less than the segment angle
		pinRadsSide := pinRads > segment.rads ? 1 : -1
		pinIndex := 1
		
		increment := segment.marks.MaxIndex()
		While (increment) {
			increment := Round((increment / 2) - .5)
			pinIndex := (pinRads > segment.rads) ? pinIndex + (pinRadsSide * increment) : pinIndex - (pinRadsSide * increment)
			pinMark := segment.marks[pinIndex]
			startMark := segment.marks[pinIndex - 2]
			;GuiControl, , % this.decoderoutput, % startMark.x "," startMark.y " to " pinMark.x "," pinMark.y
			pinRads := this.GetRads(pinMark.x - startMark.x, pinMark.y - startMark.y)
			;GuiControl, , % this.decoderoutput, % "Testing from " pinIndex " got " pinRads
		}
		
		Return pinIndex
	}
	
	
	GetHeight(segment) {
		apogeeMark := segment.marks[segment.apogeeIndex]
		;GuiControl, , % this.decoderoutput, % "Checking " segment.marks[1].x "," segment.marks[1].y " to " segment.marks[segment.marks.MaxIndex()].x "," segment.marks[segment.marks.MaxIndex()].y " against " apogeeMark.x "," apogeeMark.y
		slopeSegment := (segment.marks[segment.marks.MaxIndex()].y - segment.marks[1].y) / (segment.marks[segment.marks.MaxIndex()].x - segment.marks[1].x)
		interceptSegment := segment.marks[1].y - (slopeSegment * segment.marks[1].x)
		;GuiControl, , % this.decoderoutput, % "Segment is y = " slopeSegment " * x + " interceptSegment
		slopePerpendicular := -(1 / slopeSegment)
		interceptPerpendicular := apogeeMark.y - (slopePerpendicular * apogeeMark.x)
		;GuiControl, , % this.decoderoutput, % "Perpendicular is y = " slopePerpendicular " * x + " interceptPerpendicular
		intersection := {"x": 0, "y": 0}
		intersection.x := Round((interceptPerpendicular - interceptSegment) / (slopeSegment - slopePerpendicular))
		intersection.y := Round((slopeSegment * intersection.x) + interceptSegment)
		height := this.GetLength(apogeeMark, intersection)
		;GuiControl, , % this.decoderoutput, % "Height intersects at " intersection.x "," intersection.y " for a height of " height
		Return height
	}
	
	GetArea(segment) {
		startMark := segment.marks[1]
		endMark := segment.marks[segment.marks.MaxIndex()]
		apogeeMark := segment.marks[segment.apogeeIndex]
		;GuiControl, , % this.decoderoutput, % "start " startMark.x "," startMark.y " end " endMark.x "," endMark.y " apogee " apogeeMark.x "," apogeeMark.y 
		crossProduct := (endMark.x - startMark.x) * (endMark.y - apogeeMark.y) - (endMark.y - startMark.y) * (endMark.x - apogeeMark.x)
		indicator := crossProduct / Abs(crossProduct)
		area := indicator * (segment.length * segment.height / 2)
		;GuiControl, , % this.decoderoutput, % "Volume is " volume " after a crossproduct of " crossproduct " gave an indicator of " indicator
		Return area 
	}
}
