
Global SessionSpeedMessage
Global CurrentSpeedMessage
class SpeedViewport
{
	minimumSpeed := 6
	dequeueInterval := 1000
	showInterval := 10000
	speedEvents := []
	speedQueues := []
	
	__New()
	{
		
		Gui SpeedGUI:Default
		; Add header text
		Gui, SpeedGUI:Add, Text, x12  y9 w100  h20 vSessionSpeedMessage, % "We can speed" 
		Gui, SpeedGUI:Add, Text, x12  y29 w100  h20 vCurrentSpeedMessage, % "We can speed" 
		; Generated using SmartGUI Creator 4.0
		Gui, Show, x220 y25 h60 w124, % "Speed Viewer"
		
        this.dequeueTimer := ObjBindMethod(this, "DequeueEvents")
        dequeueTimer := this.dequeueTimer
        SetTimer % dequeueTimer, % this.dequeueInterval
		
        this.showTimer := ObjBindMethod(this, "ShowSpeed")
        showTimer := this.showTimer
        SetTimer % showTimer, % this.showInterval
	}
	
	DequeueEvents() {
		Gui SpeedGUI:Default
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
		ticks := 0
		current_in_chars := 0
		current_out_chars := 0
		current_ticks := 0
		current_horizon := ""
		current_horizon += -1, Minutes
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
		Gui SpeedGUI:Default
		GuiControl,,SessionSpeedMessage, % Round(in_chars / (ticks / 12000)) " WPM / " Round(out_chars / (ticks / 12000)) " WPM"
		GuiControl,,CurrentSpeedMessage, % Round(current_in_chars / (current_ticks / 12000)) " WPM / " Round(current_out_chars / (current_ticks / 12000)) " WPM"
	}
	
	addQueue(speedQueue) {
		this.speedQueues.Push(speedQueue)
	}
}
