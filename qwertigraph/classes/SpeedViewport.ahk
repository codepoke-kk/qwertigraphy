
Global SessionSpeedMessage
Global CurrentSpeedMessage

; Add header text
Gui, Tab
Gui, Font, s18, Verdana  ;
Gui, Add, Text, x12  y9 w250  h28 vCurrentSpeedMessage, % "0 WPM/0 WPM" 
Gui, Font, s10, Verdana  ;
Gui, Add, Text, x270  y9 w150  h28 vSessionSpeedMessage, % "0 WPM/0 WPM" 
Gui, Font

class SpeedViewport
{
	minimumSpeed := 6
	dequeueInterval := 1000
	showInterval := 10000
	speedEvents := []
	speedQueues := []
	
	__New()
	{
        this.dequeueTimer := ObjBindMethod(this, "DequeueEvents")
        dequeueTimer := this.dequeueTimer
        SetTimer % dequeueTimer, % this.dequeueInterval
		
        this.showTimer := ObjBindMethod(this, "ShowSpeed")
        showTimer := this.showTimer
        SetTimer % showTimer, % this.showInterval
	}
	
	DequeueEvents() {
		For index, speedQueue in this.speedQueues {
			Loop, % speedQueue.getSize() {
				speedEvent := speedQueue.dequeue()
				this.speedEvents.Push(speedEvent)
			}
		}
	}
	
	ShowSpeed() {
		in_chars := 0
		out_chars := 0
		ticks := 1
		current_in_chars := 0
		current_out_chars := 0
		current_ticks := 0
		current_horizon := ""
		current_horizon += -15, Seconds
		For index, speedEvent in this.speedEvents {
			if (speedEvent.wpm > this.minimumSpeed) {
				in_chars += speedEvent.in_chars
				out_chars += speedEvent.out_chars
				ticks += speedEvent.ticks
				if (speedEvent.when > current_horizon) {
					current_in_chars += speedEvent.in_chars
					current_out_chars += speedEvent.out_chars
					current_ticks += speedEvent.ticks
				} 
			}
		}
		GuiControl,,CurrentSpeedMessage, % Round(current_in_chars / (current_ticks / 12000)) " WPM / " Round(current_out_chars / (current_ticks / 12000)) " WPM"
		GuiControl,,SessionSpeedMessage, % Round(in_chars / (ticks / 12000)) " WPM / " Round(out_chars / (ticks / 12000)) " WPM"
	}
	
	addQueue(speedQueue) {
		this.speedQueues.Push(speedQueue)
	}
}
