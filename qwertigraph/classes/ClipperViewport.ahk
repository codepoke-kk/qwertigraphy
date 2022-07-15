
Gui MainGUI:Default 
Gui, Tab, Clipper
;;; Column 1 
Gui, Add, Text, x12  y64 w160 h20 , Pastable Fields:
Gui, Add, Edit, x12  y84 w800 h20 vClipperP1, Text to paste goes here
Gui, Add, Edit, x12  y104 w800 h20 vClipperP2, Text to paste goes here
Gui, Add, Edit, x12  y124 w800 h20 vClipperP3, Text to paste goes here
Gui, Add, Edit, x12  y144 w800 h20 vClipperP4, Text to paste goes here
Gui, Add, Edit, x12  y164 w800 h20 vClipperP5, Text to paste goes here
Gui, Add, Edit, x12  y184 w800 h20 vClipperP6, Text to paste goes here
Gui, Add, Edit, x12  y204 w800 h20 vClipperP7, Text to paste goes here
Gui, Add, Edit, x12  y224 w800 h20 vClipperP8, Text to paste goes here
Gui, Add, Edit, x12  y244 w800 h20 vClipperP9, Text to paste goes here
Gui, Add, Edit, x12  y264 w800 h20 vClipperP0, Text to paste goes here

class ClipperViewport
{
	interval := 500
	
	__New(engine)
	{
		this.engine := engine
	}
}