
Global SessionSpeedMessage
Global CurrentSpeedMessage

; Add header text
Gui, Tab
Gui, Font, s18, Verdana  ;
Gui, Add, Text, x12  y9 w250  h28 vCurrentSpeedMessage, % "0 WPM/0 WPM" 
Gui, Font, s8, Verdana  ;
Gui, Add, Text, x270  y9 w650  h48 vSessionSpeedMessage, % "0 WPM/0 WPM`nInput characters: 0, Output characters: 0" 
Gui, Font

class SpeedViewport
{
	minimumSpeed := 6
	dequeueInterval := 1000
	showInterval := 10000
	speedEvents := []
	speedQueues := []
	in_chars := 0
	out_chars := 0
	ticks := 1
	
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
				this.in_chars += speedEvent.in_chars
				this.out_chars += speedEvent.out_chars
				this.ticks += speedEvent.ticks
			}
		}
	}
	
	ShowSpeed() {
		current_in_chars := 0
		current_out_chars := 0
		current_ticks := 0
		current_horizon := ""
		current_horizon += -15, Seconds
		For index, speedEvent in this.speedEvents {
			if (speedEvent.wpm > this.minimumSpeed) {
				if (speedEvent.when > current_horizon) {
					current_in_chars += speedEvent.in_chars
					current_out_chars += speedEvent.out_chars
					current_ticks += speedEvent.ticks
				} 
			}
		}
		GuiControl,,CurrentSpeedMessage, % Round(current_in_chars / (current_ticks / 12000)) " WPM / " Round(current_out_chars / (current_ticks / 12000)) " WPM"
		GuiControl,,SessionSpeedMessage, % Round(this.in_chars / (this.ticks / 12000)) " WPM / " Round(this.out_chars / (this.ticks / 12000)) " WPM`nInput characters: " this.in_chars ", Output characters: " this.out_chars
	}
	
	addQueue(speedQueue) {
		this.speedQueues.Push(speedQueue)
	}
}
