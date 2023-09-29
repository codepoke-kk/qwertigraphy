
Gui MainGUI:Default
Gui, Tab, Player
;;; Column 1
; Add regex search fields
Gui, Add, Text, x12  y64 w160 h20 , Input Text:
Gui, Add, Edit, x12  y84 w800 h400 vPlayerInputText gPlayerInputText, Enter text to play here
Gui, Add, Edit, x12  y484 w800 h20 vPlayerOutputText, Text will be played here

Gui, Add, Button, x838 y64 w90 h20 gPlayerPlayText, Play

PlayerInputText() {
	; No op
}

PlayerPlayText() {
	global player
	player.playInputText()
}


class PlayerViewport
{
	interval := 500

	__New(engine)
	{
		this.engine := engine
	}

 	WmCommand(wParam, lParam){
		if (lParam = this.hPlayerPlayText) {
			this.playInputText()
		}
	}

	playInputText() {
		local
		global PlayerInputText
		global PlayerOutputFocus
		Gui MainGUI:Default
		GuiControlGet PlayerInputText
		GuiControl, Focus, PlayerOutputText
		Send, ^a{del}
		Loop, % StrLen(PlayerInputText) {
			key := Substr(PlayerInputText, A_Index, 1)
			; Tooltip, % key
			; Sleep, 500
			Switch key {
				case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m":
                    ; Tooltip, % "Group 1 sending and adding " key
                    ; Sleep, 500
					Send, % key
					this.engine.accumulator.AddKeyToToken(key)
				case "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
                    ; Tooltip, % "Group 2 sending and adding " key
                    ; Sleep, 500
					Send, % key
					this.engine.accumulator.AddKeyToToken(key)
				case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
                    ; Tooltip, % "Group 3 sending and adding " key
                    ; Sleep, 500
					Send, % key
					this.engine.accumulator.AddKeyToToken(key)
				case " ", ".", ",", "'", "[", "]":
                    ; Tooltip, % "Punctuation sending and adding " key
                    ; Sleep, 500
					; this.engine.SendToken(key)
					this.engine.accumulator.EndToken(key)
				default:
                    ; Tooltip, % "Default sending and adding " key
                    ; Sleep, 500
					this.engine.accumulator.EndToken(key)
					; Send, % ("{" key "}")
			}

			Sleep, 10
		}
	}
}
