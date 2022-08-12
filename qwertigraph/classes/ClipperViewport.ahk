
Gui MainGUI:Default
Gui, Tab, Clipper


Gui, Add, Button, Default x838 y86 w90 h20 gClipperHide, Hide
Gui, Add, Button, Default x838 y106 w90 h20 gClipperShow, Show

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
Gui, Add, Edit, x42  y224 w780 h20 vClipperP8, Ever tried. Ever failed. No matter. Try again. Fail again. Fail better. - Samuel Beckett
Gui, Add, Edit, x42  y244 w780 h20 vClipperP9, I have seen the moment of my greatness flicker, and I have seen the eternal Footman hold my coat, and snicker, and in short, I was afraid. - T.S. Eliot, The Love Song of J. Alfred Prufrock
Gui, Add, Edit, x42  y264 w780 h20 vClipperP0, I have heard the mermaids singing, each to each. I do not think that they will sing to me. - T.S. Eliot, The Love Song of J. Alfred Prufrock


Gui, Add, Button, Default x838 y324 w90 h20 gClipperLoad, Load
Gui, Add, Button, Default x838 y364 w90 h20 gClipperSave, Save

Gui, Add, Text, x12  y326 w200 h20 , Clips file name:
Gui, Add, Edit, x222  y324 w400 h20 vClipperFilename, clipper.clips
Gui, Add, Text, x12  y346 w200 h20 , Clips encryption key:
Gui, Add, Edit, x222  y344 w400 h20 vClipperKey +Password ; -WantCtrlA
Gui, Add, Text, x12  y366 w200 h20 , Verification key (required when saving):
Gui, Add, Edit, x222  y364 w400 h20 vClipperVerify +Password ; -WantCtrlA

Gui, Add, Text, x12  y400 w800 h100 , Replace the contents of the 10 "P" fields as you please. When you type p# (any number from 0-9), it will paste the corresponding clip at the insertion point. You can also chord p#, to make it happen faster. If you like a set of clips, you can save it to your personal folder with the name given in the field above then reload it at a later date. If you provide a "clips encryption key", your clips will be written to the disk after encrypting with that key. Do not fool yourself into thinking this is awesome encryption. It is crackable, but it would take a little while to crack it. There is a more secure password entry tool built into the system, but you must re-enter the username and password with each restart. The username and password will not be written to disk. To use that, type or chord b1 or b2 for the first pair and b3 or b4 for the second pair. When you type or chord any of those 4 codes the system will prompt you to supply a username and then a password with first use, then will paste them thereafter. b1/b3 paste only the password. b2/b4 paste the username then tab once then paste the password. It's a huge time saver if you log on as many times in a session as I do.


ClipperSave() {
	global clipper
	clipper.saveClips()
}

ClipperLoad() {
	global clipper
	clipper.loadClips()
}

ClipperHide() {
	global clipper
	clipper.hideClips()
}

ClipperShow() {
	global clipper
	clipper.showClips()
}

class ClipperViewport
{
	interval := 500
	logQueue := new Queue("ClipperQueue")
	logVerbosity := 1

	__New(qenv)
	{
		this.qenv := qenv
        this.padlength := 31
        this.padboundary := "zjacq"
	}

    initialize() {
        Gui MainGUI:Default
        Gui, Tab, Clipper

        if (this.qenv.Properties.ClipperCurrentFilename) {
            GuiControl, Text, ClipperFilename, % this.qenv.Properties.ClipperCurrentFilename
            this.loadClips()
        }
        this.hideClips()
    }

 	WmCommand(wParam, lParam){
		if (lParam = this.hClipperSave) {
			this.saveClips()
		}
		if (lParam = this.hClipperLoad) {
			this.loadClips()
		}
	}
    GeneratePadding(padlen) {
        Local
        pad := ""
        Loop, %padlen% {
            Random, letter, 97, 122
            pad := pad . Chr(letter)
        }
        Return, pad
    }

    ; abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890 !@#$%^&*()
    Encrypt(clipperkey, plaintext) {

        ; Only encrypt if we have a key
        if (!StrLen(clipperkey)) {
            Return plaintext
        }

        padding := this.GeneratePadding(this.padlength)
		this.logEvent(4, "Encrypting with padding " padding)
        plaintext := padding . this.padboundary . plaintext

        functionkey := clipperkey
        ; the simple encryption used here requires the key be longer than the plaintext
        ; I'm just going to concatenate the key to itself as many times as needed
        Loop
        {
            if (StrLen(functionkey) > StrLen(plaintext)) {
                break
            }
            functionkey .= clipperkey
        }
        Encrypted := ""
        Loop, Parse, plaintext
        {
            Encrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(functionkey,A_Index,1))-32))+32)
        }

        this.logEvent(4, "Encrypted hash is " Encrypted)
        Return Encrypted
    }
    Decrypt(clipperkey, cipherhash) {
        ; Only decrypt if we have a key
        if (!StrLen(clipperkey)) {
            Return cipherhash
        }
        this.logEvent(4, "Cipher hash is " cipherhash)
        functionkey := clipperkey
        ; the simple encryption used here requires the key be longer than the plaintext
        ; I'm just going to concatenate the key to itself as many times as needed
        Loop
        {
            if (StrLen(functionkey) > StrLen(cipherhash)) {
                break
            }
            functionkey .= clipperkey
        }
		this.logEvent(4, "Decrypting with functionkey " functionkey)
        Decrypted := ""
        Loop, Parse, cipherhash
        {
            Decrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(functionkey,A_Index,1))-32))+32)
        }

        if (SubStr(Decrypted, this.padlength + 1, StrLen(this.padboundary)) != this.padboundary) {
            ; Did not find the embedded pad boundary, which means we did not decrypt. Give no clues.
            ; If you're reading this, you can crack this. But if you're reading this, nothing I can do could stop you
            ; Putting this readable boundary into the decrypted string gives you a target
            ; But it allows me to detect decryption failure and hide partial decryption hints from the UI
            ; I'm happy to learn from any willing to teach
            Return "Decryption failure"
        }

        Return SubStr(Decrypted, (this.padlength + StrLen(this.padboundary) + 1))
    }

	saveClips() {
        home := this.qenv.personalDataFolder
        GuiControlGet filename,, ClipperFilename
        GuiControlGet clipperkey,, ClipperKey
        GuiControlGet clipperverify,, ClipperVerify

        if (StrLen(clipperkey)) {

            if (clipperverify != clipperkey) {
                Msgbox % "The key you entered for verification does not match the key currently in the encryption key field. If you do not know that key, you will not be able to retrieve the data there encrypted. Please verify again. Clips not saved."
                Return
            }
        }


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
        fileHandleClipper := FileOpen(home "\" filename, "w", "UTF-16")
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p0))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p1))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p2))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p3))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p4))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p5))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p6))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p7))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p8))
        fileHandleClipper.WriteLine(this.Encrypt(clipperkey, p9))
        fileHandleClipper.Close()


        this.logEvent(1, "Saved clipper clips")

        this.qenv.Properties.ClipperCurrentFilename := filename
		this.qenv.saveProperties()
    }

	loadClips() {
        home := this.qenv.personalDataFolder
        GuiControlGet filename,, ClipperFilename
        GuiControlGet clipperkey,, ClipperKey

        iterator := 0
        Loop,Read, % home "\" filename, "UTF-16"   ;read clips
		{
            GuiControl, Text, % "ClipperP" iterator, % this.decrypt(clipperkey, A_LoopReadLine)
            iterator++
		}
        this.logEvent(1, "Loaded clipper clips")

    }

    hideClips() {
        GuiControl, Hide, ClipperP1
        GuiControl, Hide, ClipperP2
        GuiControl, Hide, ClipperP3
        GuiControl, Hide, ClipperP4
        GuiControl, Hide, ClipperP5
        GuiControl, Hide, ClipperP6
        GuiControl, Hide, ClipperP7
        GuiControl, Hide, ClipperP8
        GuiControl, Hide, ClipperP9
        GuiControl, Hide, ClipperP0
    }

    showClips() {
        GuiControl, Show, ClipperP1
        GuiControl, Show, ClipperP2
        GuiControl, Show, ClipperP3
        GuiControl, Show, ClipperP4
        GuiControl, Show, ClipperP5
        GuiControl, Show, ClipperP6
        GuiControl, Show, ClipperP7
        GuiControl, Show, ClipperP8
        GuiControl, Show, ClipperP9
        GuiControl, Show, ClipperP0
    }

	LogEvent(verbosity, message)
	{
		if (verbosity <= this.logVerbosity)
		{
			event := new LoggingEvent("clipper",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}