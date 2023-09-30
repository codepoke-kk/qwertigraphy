/*
- Edge cases to remember when testing 
Alt-tab must work 
Shifted number keys must work 
Shifted symbol keys must work 
Mask passwords in logs
Control+letter must cancel its own token
*/

#InstallKeybdHook
engine := {}

#Include *i %A_AppData%\Qwertigraph\personal_functions.ahk
#Include scripts\default.ahk

#Include classes\EngineParts\Keyboard.ahk
#Include classes\EngineParts\Listener.ahk
#Include classes\EngineParts\Accumulator.ahk
#Include classes\EngineParts\TokenEvent.ahk
#Include classes\EngineParts\SerialExpander.ahk
#Include classes\EngineParts\ChordExpander.ahk
#Include classes\EngineParts\Sender.ahk
#Include classes\EngineParts\Coacher.ahk
#Include classes\EngineParts\Dashboarder.ahk
#Include classes\EngineParts\Recorder.ahk

class MappingEngine {
	Static ContractedEndings := "s,d,t,m,re,ve,ll,r,v,l"
	
	map := ""
	dashboard := ""
	last_end_key := ""
	characters_typed_raw := ""
	characters_typed_final := ""
	time_taken := ""
	average_raw_wpm := ""
	average_final_wpm := ""
	discard_ratio := ""
	input_text_buffer := ""
	logQueue := new Queue("EngineQueue")
	logVerbosity := 3
	tip_power_threshold := 1
	speedQueue := new Queue("SpeedQueue")
	coachQueue := new Queue("CoachQueue")
	penQueue := new Queue("PenQueue")
	dashboardQueue := new Queue("DashboardQueue")
	
	nullQwerd := new DictionaryEntry("null,,,,0,Could add,null_dictionary.csv")

	__New(map, aux)	{
		this.map := map
		this.aux := aux
		
		this.keyboard := New Keyboard(this)
		this.listener := New Listener(this)
		this.accumulator := New Accumulator(this)
		this.serialexpander := New SerialExpander(this)
		this.chordexpander := New ChordExpander(this)
		this.sender := New Sender(this)
		this.coacher := New Coacher(this)
		this.dashboarder := New Dashboarder(this)
		this.recorder := New Recorder(this)
		this.record := []
		
	}
		
	Start() {
		this.listener.Start(this.accumulator)
	}	 
	Stop() 	{
		this.listener.Stop(this.accumulator)
	}
	
	NotifySerialToken(token) {
        ; Called by the Accumulator upon EndToken
		this.logEvent(4, "Notified serial token ended by " token.ender " with " token.input)
		expanded_token := this.serialexpander.Expand(token)
		this.NotifyExpandedToken(expanded_token)
	}
	
	NotifyExpandedToken(token) {
        ; Called by the ChordExpander upon SendChord
		this.logEvent(4, "Notified expanded token ended by " token.ender " with " token.input)
		sent_token := this.sender.Send(token)
		coached_token := this.coacher.Coach(sent_token)
		dashboarded_token := this.dashboarder.Indicate(coached_token)
		this.recorder.Record(dashboarded_token)
		this.logEvent(4, "Completed handling of token #" this.record.MaxIndex())
	}
	
	ResetInput() {
		this.logEvent(2, "Input reset by function ")
		this.listener.CancelToken("{LButton}")
	}
    
    setKeyboardChordWindowIncrements() {
        
        increment := Round(this.keyboard.ChordReleaseWindow / 3)
        Loop, 26 {
            this.keyboard.ChordReleaseWindows[A_Index] := A_Index * increment
        }
    }

	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("engine",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}
