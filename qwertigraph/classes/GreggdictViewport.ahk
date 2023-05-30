

;Gui Add, Edit, w916 r1 vURL, file://%a_scriptdir%/greggdict/pages/001.png
;Gui Add, Button, x+6 yp w44 Default, Go
;Gui Add, Edit, x200 y200 w200 h20, Text
;Gui Add, ActiveX,x12 y84 w916 h476 vBrowser, Shell.Explorer
;ComObjConnect(WB, WB_events)  ; Connect WB's events to the WB_events class object.
;WB.Navigate(A_ScriptDir "\greggdict\pages\001.png" )

global greggdictbrowser
Gui MainGUI:Default
Gui, Tab, GreggDict
Gui Add, Edit, x200 y200 w200 h20, Edited
Gui Add, ActiveX, x12 y0 w916 h550 vgreggdictbrowser, msedge.exe
;ComObjConnect(WB, WB_events)  ; Connect WB's events to the WB_events class object.
; greggdictbrowser.Navigate(A_ScriptDir "\greggdict\pages\honepad.html`?page=170.png`&x=1188`&y=2325" )

class GreggDictViewport
{
	interval := 500
	logQueue := new Queue("GreggdictQueue")
	logVerbosity := 1
    greggdictbrowser := ""
	greggdictroot := "greggdict"
	greggdicts := ComObjCreate("Scripting.Dictionary")

	__New(qenv)
	{
		this.qenv := qenv

		; Read in the greggdict list
		LineCount := 0
		Loop,Read, % this.greggdictroot "\reference.csv"   ;read dictionary into Scripting.Dictionaries
		{
			if (A_Index = 1) {
				; We do nothing with the title row
				Continue
			} else {
				LineCount++
			}

			newgreggdictword := new GreggdictEntry(A_LoopReadLine)
			this.logEvent(4, "Greggdict word " newgreggdictword.word " as " newgreggdictword.page "," newgreggdictword.link "," newgreggdictword.x "," newgreggdictword.y " from " A_LoopReadLine)

			this.greggdicts.item(newgreggdictword.word) := newgreggdictword

            ; Flood system with possible matches
            wordbuffer := newgreggdictword.word
            Loop
            {
                wordbuffer := SubStr(wordbuffer, 1, StrLen(wordbuffer) -1)
                if (StrLen(wordbuffer) < 1) {
                    break
                }
                if (! this.greggdicts.item(wordbuffer).x) {
                    this.greggdicts.item(wordbuffer) := newgreggdictword
                }
            }
		}
		this.logEvent(1, "Loaded greggdicts map resulting in " LineCount " entries")
		this.logEvent(1, "Thing entry link = " this.greggdicts.item("thing").link ".")

	}

    initialize() {
        Gui MainGUI:Default
        Gui, Tab, GreggDict

    }

 	WmCommand(wParam, lParam){
		if (lParam = this.hNextPage) {
			this.nextPage()
		}
		if (lParam = this.hPreviousPage) {
			this.previousPage()
		}
	}
	nextPage() {
    }

	previousPage() {

    }

	LogEvent(verbosity, message)
	{
		if (verbosity <= this.logVerbosity)
		{
			event := new LoggingEvent("greggdict",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}