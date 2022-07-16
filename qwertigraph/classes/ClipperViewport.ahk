
Gui MainGUI:Default 
Gui, Tab, Clipper


Gui, Add, Text, x12  y64 w160 h20 , Pastable Fields:
Gui, Add, Text, x12  y86 w160 h20 , P1:
Gui, Add, Text, x12  y106 w160 h20 , P2:
Gui, Add, Text, x12  y126 w160 h20 , P3:
Gui, Add, Text, x12  y146 w160 h20 , P4:
Gui, Add, Text, x12  y166 w160 h20 , P5:
Gui, Add, Text, x12  y186 w160 h20 , P6:
Gui, Add, Text, x12  y206 w160 h20 , P7:
Gui, Add, Text, x12  y226 w160 h20 , P8:
Gui, Add, Text, x12  y246 w160 h20 , P9:
Gui, Add, Text, x12  y266 w160 h20 , P0:
Gui, Add, Edit, x42  y84 w780 h20 vClipperP1, https://github.com/codepoke-kk/qwertigraphy
Gui, Add, Edit, x42  y104 w780 h20 vClipperP2, https://greggshorthand.github.io
Gui, Add, Edit, x42  y124 w780 h20 vClipperP3, https://github.com/richyliu/greggdict
Gui, Add, Edit, x42  y144 w780 h20 vClipperP4, kevinknox@embarqmail.com
Gui, Add, Edit, x42  y164 w780 h20 vClipperP5, https://facebook.com
Gui, Add, Edit, x42  y184 w780 h20 vClipperP6, https://youtube.com
Gui, Add, Edit, x42  y204 w780 h20 vClipperP7, The greatest of these is love.
Gui, Add, Edit, x42  y224 w780 h20 vClipperP8, Ever tried. Ever failed. No matter. Try again. Fail again. Fail better. - Samuel Becket
Gui, Add, Edit, x42  y244 w780 h20 vClipperP9, I have seen the moment of my greatness flicker, and I have seen the eternal Footman hold my coat, and snicker, and in short, I was afraid. - T.S. Eliot, The Love Song of J. Alfred Prufrock
Gui, Add, Edit, x42  y264 w780 h20 vClipperP0, I have heard the mermaids singing, each to each. I do not think that they will sing to me. - T.S. Eliot, The Love Song of J. Alfred Prufrock


Gui, Add, Button, Default x838 y324 w90 h20 gClipperSave, Save
Gui, Add, Button, Default x838 y344 w90 h20 gClipperLoad, Load

Gui, Add, Text, x12  y326 w100 h20 , Clips file name:
Gui, Add, Edit, x122  y324 w400 h20 vClipperFilename, clipper.clips
Gui, Add, Text, x12  y346 w100 h20 , Clips encryption key:
Gui, Add, Edit, x122  y344 w400 h20 vClipperKey +Password ; -WantCtrlA

Gui, Add, Text, x12  y400 w800 h100 , Replace the contents of the 10 "P" fields as you please. When you type p# (any number from 0-9), it will paste the corresponding clip at the insertion point. You can also chord p#, to make it happen faster. If you like a set of clips, you can save it to your personal folder with the name given in the field above then reload it at a later date. Encryption does not yet work. 


ClipperSave() {
	global clipper
	clipper.saveClips()
}

ClipperLoad() {
	global clipper
	clipper.loadClips()
}

class ClipperViewport
{
	interval := 500
	
	__New(qenv)
	{
		this.qenv := qenv
	}
 
 	WmCommand(wParam, lParam){
		if (lParam = this.hClipperSave) {
			this.saveClips()
		}
		if (lParam = this.hClipperLoad) {
			this.loadClips()
		}
	}	
    
	saveClips() {
        home := this.qenv.personalDataFolder
        GuiControlGet filename,, ClipperFilename
        
        GuiControlGet p0,, ClipperP0
        GuiControlGet p1,, ClipperP1
        GuiControlGet p2,, ClipperP2
        GuiControlGet p3,, ClipperP3
        GuiControlGet p4,, ClipperP4
        GuiControlGet p5,, ClipperP5
        GuiControlGet p6,, ClipperP6
        GuiControlGet p7,, ClipperP7
        GuiControlGet p8,, ClipperP8
        GuiControlGet p9,, ClipperP9
        fileHandleClipper := FileOpen(home "\" filename, "w")
        fileHandleClipper.WriteLine(p0)
        fileHandleClipper.WriteLine(p1)
        fileHandleClipper.WriteLine(p2)
        fileHandleClipper.WriteLine(p3)
        fileHandleClipper.WriteLine(p4)
        fileHandleClipper.WriteLine(p5)
        fileHandleClipper.WriteLine(p6)
        fileHandleClipper.WriteLine(p7)
        fileHandleClipper.WriteLine(p8)
        fileHandleClipper.WriteLine(p9)
        fileHandleClipper.Close()
    }
    
	loadClips() {
        home := this.qenv.personalDataFolder
        GuiControlGet filename,, ClipperFilename
        
        iterator := 0
        Loop,Read, % home "\" filename   ;read clips
		{
            GuiControl, Text, % "ClipperP" iterator, %A_LoopReadLine%
            iterator++
		}
    }
}