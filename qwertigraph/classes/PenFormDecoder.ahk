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
		this.threequarterpi := 4 * ATan(1) + 2 * ATan(1)
		this.twothirdspi := 8 * ATan(1) / 3
		this.halfpi := 2 * ATan(1)
		this.thirdpi := 4 * ATan(1) / 3
		this.quarterpi := ATan(1)
		this.eighthpi := ATan(1) / 2
		this.decoderoutput := decoderoutput
		this.lastMark := 0
		
		GuiControl, , % this.decoderoutput, % "Loaded decoder"
	}
	
	SmoothPenForm(marks) {
		smooths := []
		dxs := []
		dys := []
		for index, mark in marks {
			dxs.Push(mark.dx)
			dys.Push(mark.dy)
		}
		ddxs := this.GetDDeltas(dxs)
		ddys := this.GetDDeltas(dys)
		smoothDxs := this.SmoothDeltas(dxs, ddxs)
		smoothDys := this.SmoothDeltas(dys, ddys)
		GuiControl, , % this.decoderoutput, % "Smoothed dxs " smoothDxs.MaxIndex() " from " dxs.MaxIndex()
		lastMark := marks[1]
		lastMark.x -= 100
		lastMark.y += 100
		;lastMark := New WriterMark(firstMark.x, firstMark.x, firstMark.dx, firstMark.dy, firstMark.dt, firstMark.t)
		for index, mark in marks {
			smooth := New WriterMark(lastMark.x + smoothDxs[index], lastMark.y + smoothDys[index], smoothDxs[index], smoothDys[index], mark.dt, mark.t)
			smooths.Push(smooth)
			lastMark := smooth
		}
		
		Return smooths
	}
	SmoothDeltas(deltas, dDeltas) {
		;GuiControl, , % this.decoderoutput, % "Smoothing " deltas.MaxIndex()
		smoothDeltas := []
		for index, delta in deltas {
			;smoothDeltas.Push(delta * 3)
			;GuiControl, , % this.decoderoutput, % "Smoothing  " index
			dDelta := dDeltas[index]
			averageDDelta := Round(this.SliceAndAverageArray(dDeltas, index - 2, index + 2))
			carry := dDelta - averageDDelta
			smoothDeltas.Push(delta - carry)
			delta := delta - carry
			if (index < deltas.MaxIndex()) {
				deltas[index + 1] += carry
			}
		}
		;GuiControl, , % this.decoderoutput, % "Returning " smoothDeltas.MaxIndex()
		Return smoothDeltas
	}
	GetDDeltas(deltas) {
		;GuiControl, , % this.decoderoutput, % "Smoothing " deltas.MaxIndex()
		dDeltas := []
		for index, delta in deltas {
			prior := (index = 1) ? delta : deltas[index - 1]
			dDeltas.Push(delta - prior)
		}
		;GuiControl, , % this.decoderoutput, % "Returning " smoothDeltas.MaxIndex()
		Return dDeltas
	}
	SliceAndAverageArray(arr, begin, end) {
		begin := Max(1, begin)
		end := Min(end, arr.MaxIndex())
		sum := 0
		elements := (end - begin) + 1
		index := 0
		;GuiControl, , % this.decoderoutput, % "Slice looping " elements " elements" 
		Loop, % elements {
			sum += arr[begin + index]
			index += 1
			;GuiControl, , % this.decoderoutput, % "Added " arr[begin + index] " to sum and got " sum " at index " index
		}
		;GuiControl, , % this.decoderoutput, % "Slice begin " begin ", end " end ", sum " sum ", elements " elements
		Return (sum / elements)
	}
	
	DecodePenForm(marks) {
		this.marks := marks
		this.segments := []
		GuiControl, , % this.decoderoutput, % "Received " this.marks.MaxIndex() " marks"
		this.AugmentMarks()
		this.segments := this.SegmentPenForm()
		Return this.segments 
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
		inflections := this.GetInflections(this.marks)
		segments := this.GetSegments(this.marks, inflections)
		Return segments 
		
;		startIndex := 1
;		for index, inflection in inflections {
;			GuiControl, , % this.decoderoutput, % "Looping inflection " index " is " inflection.x "," inflection.y " at " inflection.index
;			segment := this.GetSegment(inflection.type, startIndex, inflection.index) 
;			this.segments.Push(segment)
;			startIndex := inflection.index
;		}
;		GuiControl, , % this.decoderoutput, % "Last non-inflection from " startIndex " to " this.marks.MaxIndex()
;		segment := this.GetSegment("final", startIndex, this.marks.MaxIndex()) 
;		this.segments.Push(segment)
;		Return



;		startIndex := 1
;		for endindex, mark in this.marks 
;		{
;			segmenttype := this.DetectNewSegment(startindex, endindex)
;			if (segmenttype) {
;				segment := this.GetSegment(segmenttype, startIndex, endindex) 
;				this.segments.Push(segment)
;				startIndex := endindex + 1
;				;GuiControl, , % this.decoderoutput, % "New segment " segment.length "@" segment.rads " covering " segment.area
;			}
;		}
;		segment := this.GetSegment("final", startIndex, endindex) 
;		this.segments.Push(segment)
;		;GuiControl, , % this.decoderoutput, % "Final segment " segment.length "@" segment.rads " covering " segment.area
	}
	
	GetSegments(marks, inflections) {
		segments := []
		startIndex := 1
		; Loop across all inflections, looking forward to see how this segment plays with the future segments 
		for index, inflection in inflections {
			; types are continuous, curve, turn, reversal
			; If inflection is a reversal, then this is a segment end in itself
			if (inflection.type := "reversal") {
				segment := this.GetSegment("discontinuity", startIndex, inflection.index)
				startIndex := segment.endindex + 1
				segments.Push(segment)
			} else if (index = inflections.MaxIndex()) {
				segment := this.GetSegment("final", startIndex, marks.MaxIndex())
				segments.Push(segment)
			} else {
				; Else, some next inflection probably indicates where this one ends
				if (inflection.index + 5 <= inflections[index + 1].index) {
					; If the next is nearby, then just subsume it into this one
					; No operation
				} else if (inflection.sign != inflections[index + 1].sign) {
					; If the next bends the other way, then segment end is probably between them
					segment := this.GetSegment("recurve", startIndex, ((inflection.index + inflections[index + 1]) / 2))
					startIndex := segment.endindex + 1
					segments.Push(segment)
				} else if ((inflection.sign = inflections[index + 1].sign)
					and (inflection.sign = inflections[index + 2].sign)
					and (inflection.sign = inflections[index + 3].sign)) {
					; If the next 3 all bend this direction, then look for a loop
					segment := this.GetSegment("loop", startIndex, (inflections[index + 3].index))
					startIndex := segment.endindex + 1
					segments.Push(segment)
				} else {
					; If the trunk of this segment is straight, and the bend is significant, this may be a straight segment 
					segment := this.GetSegment("recurve", startIndex, inflection.index)
					startIndex := segment.endindex + 1
					segments.Push(segment)
				}
			}
		}
		Return segments 
	}
	
	GetSegment(segmenttype, startindex, endindex) {
		segment := {"startindex": startindex, "endindex": endindex, "type": segmenttype, "length": 0, "rads": 0, "apogeeIndex": 0, "height": 0, "area": 0}
		segment.length := this.GetLength(this.marks[segment.startindex], this.marks[segment.endindex])
		segment.rads := this.GetRads((this.marks[segment.endindex].x - this.marks[segment.startindex].x), (this.marks[segment.endindex].y - this.marks[segment.startindex].y))
		segment.apogeeIndex := this.GetApogeeIndex(segment)
		segment.height := this.GetHeight(segment)
		segment.area := this.GetArea(segment)
		GuiControl, , % this.decoderoutput, % "New " segment.type " segment " segment.length "@" segment.rads " with height " segment.height " covering " segment.area
		Return segment 
	}
	
	GetInflections(marks) {
		inflections := []
		firstMark := marks[1]
		lastMark := marks[marks.MaxIndex()]
		if (marks.MaxIndex() < 10) {
			; Just guess at anything of less than this many marks
			inflection := {"x": ((lastMark.x - firstMark.x > 0) ? -1 : 1), "y": ((lastMark.y - firstMark.y > 0) ? -1 : 1), "index": marks.MaxIndex()}
			inflections.Push(inflection)
			Return inflections
		}
		proceeding := (marks[8].x - firstMark.x) > 0 ? 1 : -1
		diving := (marks[8].y - firstMark.y) > 0 ? 1 : -1
		for index, mark in marks {
			if (index + 6 <= marks.Maxindex()) {
				; Don't analyze the last 6 marks
				;GuiControl, , % this.decoderoutput, % "Analyzing " index " with " proceeding "," diving
				if (mark.dx * proceeding < 0) {
					; Direction has flipped, now see whether this is transient or a real turn
					if ((marks[index + 6].x - mark.x) * proceeding <= 0) {
						proceeding := -(proceeding)
						;GuiControl, , % this.decoderoutput, % "Found x inflection and proceeding is now " proceeding
						if (inflections.MaxIndex() and (index - inflections[inflections.MaxIndex()].index < 6)) {
							; if we already have an inflection within 5 index of this point, then blend these two 
							inflections[inflections.MaxIndex()].x := proceeding
							inflections[inflections.MaxIndex()].index := (index - 1 + inflections[inflections.MaxIndex()].index) / 2
						} else {
							;GuiControl, , % this.decoderoutput, % "Creating new x inflection and proceeding is now " proceeding
							inflection := {"x": proceeding, "y": 0, "index": index - 1}
							inflections.Push(inflection)
						}
					} else {
						;GuiControl, , % this.decoderoutput, % "Ignoring this x flip as transient"
					}
				}
				if (mark.dy * proceeding < 0) {
					; Direction has flipped, now see whether this is transient or a real turn
					if ((marks[index + 6].y - mark.y) * diving <= 0) {
						diving := -(diving)
						;GuiControl, , % this.decoderoutput, % "Found y inflection and diving is now " diving 
						if (inflections.MaxIndex() and (index - inflections[inflections.MaxIndex()].index < 6)) {
							;GuiControl, , % this.decoderoutput, % "Blending with inflections[ " inflections.MaxIndex() "]"
							; if we already have an inflection within 5 index of this point, then blend these two 
							inflections[inflections.MaxIndex()].y := diving
							inflections[inflections.MaxIndex()].index := (index - 1 + inflections[inflections.MaxIndex()].index) / 2
							;GuiControl, , % this.decoderoutput, % "Blending with inflections[ " inflections.MaxIndex() "] now at index " inflections[inflections.MaxIndex].index
						} else {
							;GuiControl, , % this.decoderoutput, % "Creating new y inflection"
							inflection := {"x": 0, "y": diving, "index": index - 1}
							inflections.Push(inflection)
						}
					} else {
						;GuiControl, , % this.decoderoutput, % "Ignoring this y flip as transient"
					}
				}
			}
			;GuiControl, , % this.decoderoutput, % "Inflection count after " index " is " inflections.MaxIndex()
		}
		GuiControl, , % this.decoderoutput, % "Inflection count after " index " is " inflections.MaxIndex()
		for index, inflection in inflections {
			trunkMark := marks[inflection.index - 6]
			branchMark := marks[inflection.index]
			growthMark := marks[inflection.index + 6]
			trunkRads := this.GetRads(branchMark.x - trunkMark.x, branchMark.y - trunkMark.y)
			growthRads := this.GetRads(growthMark.x - branchMark.x, growthMark.y - branchMark.y)
			rads := growthRads - trunkRads
			inflection.rads := rads
			inflection.sign := Abs(rads) / rads
			if (abs(rads) < this.eighthpi) {
				inflection.type := "continuous"
			} else if (abs(rads) < this.thirdpi) {
				inflection.type := "curve"
			} else if (abs(rads) < this.twothirdspi) {
				inflection.type := "turn"
			} else {
				inflection.type := "reversal"
			}
			GuiControl, , % this.decoderoutput, % "Inflection " index " covers " rads " rads from " trunkRads " to " growthRads
		}
		Return inflections
	}
	
	DetectNewSegment(startindex, endindex) {
		if (this.DetectDiscontinuity(startindex, endindex)) {
			Return "discontinuity"
		} else if (this.DetectRecurve(startindex, endindex)) {
			Return "recurve"
		} else if (this.DetectIntersection(startindex, endindex)) {
			Return "intersection"
		} else if (this.DetectDisjoin(startindex, endindex)) {
			Return "disjoin"
		} else {
			Return ""
		}
	}
	
	DetectRecurve(startindex, endindex) {
		; The first few marks of a new outline are shaky. Make sure we skip them. 
		if ((endindex - startindex < 30) or (this.marks.MaxIndex() - endindex < 30)) {
			Return false
		}
		trunkStart := this.marks[endindex-23]
		trunkMid1 := this.marks[endindex-16]
		trunkMid2 := this.marks[endindex-9]
		trunkEnd := this.marks[endindex-3]
		growthStart := this.marks[endindex+3]
		growthMid1 := this.marks[endindex+9]
		growthMid2 := this.marks[endindex+16]
		growthEnd := this.marks[endindex+23]
		trunkRads1 := this.GetRads(trunkMid1.x - trunkStart.x, trunkMid1.y - trunkStart.y)
		trunkRads2 := this.GetRads(trunkMid2.x - trunkMid1.x, trunkMid2.y - trunkMid1.y)
		trunkRads3 := this.GetRads(trunkEnd.x - trunkMid2.x, trunkEnd.y - trunkMid2.y)
		branchRads := this.GetRads(growthStart.x - trunkEnd.x, growthStart.y - trunkEnd.y)
		growthRads1 := this.GetRads(growthMid1.x - growthStart.x, growthMid1.y - growthStart.y)
		growthRads2 := this.GetRads(growthMid2.x - growthMid1.x, growthMid2.y - growthMid1.y)
		growthRads3 := this.GetRads(growthEnd.x - growthMid2.x, growthEnd.y - growthMid2.y)
		trunkDiffRads := trunkRads3 - trunkRads1
		trunkDirection := Abs(trunkDiffRads) / trunkDiffRads
		branchDiffRads := growthRads1 - trunkRads3
		growthDiffRads := growthRads3 - growthRads1
		growthDirection := Abs(growthDiffRads) / growthDiffRads
		
		if (growthDirection != trunkDirection) {
			if (growthDirection > 0) {
				if ((growthRads3 > growthRads2)
				and (growthRads2 > growthRads1)
				and (branchRads < .2)
				and (trunkRads3 < trunkRads2)
				and (trunkRads2 < trunkRads1)) {
					GuiControl, , % this.decoderoutput, % "Recurve with " trunkRads1 "," trunkRads2 "," trunkRads3 "," branchRads "," growthRads1 "," growthRads2 "," growthRads3
					GuiControl, , % this.decoderoutput, % "Recurve with " trunkDiffRads " through " branchDiffRads " to " growthDiffRads " ending at index " endindex
					Return true 
				} else if ((growthRads3 < growthRads2)
				and (growthRads2 < growthRads1)
				and (branchRads < .2)
				and (trunkRads3 > trunkRads2)
				and (trunkRads2 > trunkRads1)) {
					GuiControl, , % this.decoderoutput, % "Recurve with " trunkRads1 "," trunkRads2 "," trunkRads3 "," branchRads "," growthRads1 "," growthRads2 "," growthRads3
					GuiControl, , % this.decoderoutput, % "Recurve with " trunkDiffRads " through " branchDiffRads " to " growthDiffRads " ending at index " endindex
					Return true 
				}
			}
		}
	}
	DetectDiscontinuity(startindex, endindex) {
		; Look at the angles backward 5 and forward 5. If they differ by more than half-pi and less than 3/4 pi, then it's a new segment 
		;GuiControl, , % this.decoderoutput, % "Seeking discontinuity at index " endindex " from base " startindex
		; The first few marks of a new outline are shaky. Make sure we skip them. 
		if ((endindex - startindex < 15) or (this.marks.MaxIndex() - endindex < 5)) {
			Return false
		}
		trunkStart := this.marks[endindex-5]
		trunkEnd := this.marks[endindex-1]
		growthStart := this.marks[endindex]
		growthEnd := this.marks[endindex+4]
		trunkRads := this.GetRads(trunkEnd.x - trunkStart.x, trunkEnd.y - trunkStart.y)
		growthRads := this.GetRads(growthEnd.x - growthStart.x, growthEnd.y - growthStart.y)
		
		if ((Abs(growthRads - trunkRads) > this.halfpi) and (Abs(growthRads - trunkRads) < this.threequarterpi)) {
			GuiControl, , % this.decoderoutput, % "Discontinuity with " trunkRads " to " growthRads " ending at index " endindex
			Return true 
		}
	}
	DetectIntersection(startindex, endindex) {
		Return false 
	}
	DetectDisjoin(startindex, endindex) {
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
		startMark := this.marks[segment.startindex]
		pinMark := segment.marks[segment.startindex + 2]
		pinRads := this.GetRads(pinMark.x - startMark.x, pinMark.y, startMark.y)
		;GuiControl, , % this.decoderoutput, % "Start Rads are " pinRads " and seeking " segment.rads 
		
		; If start angle is bigger than the segment's angle, then we want to find the index where the pinRads are less than the segment angle
		pinRadsSide := pinRads > segment.rads ? 1 : -1
		pinIndex := 1
		
		increment := segment.endindex - segment.startindex
		While (increment) {
			increment := Round((increment / 2) - .5)
			pinIndex := (pinRads > segment.rads) ? pinIndex + (pinRadsSide * increment) : pinIndex - (pinRadsSide * increment)
			pinMark := this.marks[pinIndex + segment.startindex]
			startMark := this.marks[pinIndex + segment.startindex - 2]
			;GuiControl, , % this.decoderoutput, % startMark.x "," startMark.y " to " pinMark.x "," pinMark.y
			pinRads := this.GetRads(pinMark.x - startMark.x, pinMark.y - startMark.y)
			;GuiControl, , % this.decoderoutput, % "Testing from " pinIndex " got " pinRads
		}
		
		Return pinIndex
	}
	
	
	GetHeight(segment) {
		apogeeMark := this.marks[segment.apogeeIndex]
		;GuiControl, , % this.decoderoutput, % "Checking " this.marks[segment.startindex].x "," this.marks[segment.startindex].y " to " this.marks[segment.endindex].x "," this.marks[segment.endindex].y " against " apogeeMark.x "," apogeeMark.y
		slopeSegment := (this.marks[segment.endindex].y - this.marks[segment.startindex].y) / (this.marks[segment.endindex].x - this.marks[segment.startindex].x)
		interceptSegment := this.marks[segment.startindex].y - (slopeSegment * this.marks[segment.startindex].x)
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
		startMark := this.marks[segment.startindex]
		endMark := this.marks[segment.endindex]
		apogeeMark := this.marks[segment.apogeeIndex]
		;GuiControl, , % this.decoderoutput, % "start " startMark.x "," startMark.y " end " endMark.x "," endMark.y " apogee " apogeeMark.x "," apogeeMark.y 
		crossProduct := (endMark.x - startMark.x) * (endMark.y - apogeeMark.y) - (endMark.y - startMark.y) * (endMark.x - apogeeMark.x)
		indicator := crossProduct / Abs(crossProduct)
		area := indicator * (segment.length * segment.height / 2)
		;GuiControl, , % this.decoderoutput, % "Volume is " volume " after a crossproduct of " crossproduct " gave an indicator of " indicator
		Return area 
	}
}
