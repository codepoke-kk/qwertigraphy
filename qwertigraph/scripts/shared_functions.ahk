;;; Date/Time Methods
SendDate(qwerd, word, end_key) {
    local
    FormatTime, dateStamp, , MM/dd/yyyy
    Send, % dateStamp
}
SendTime(qwerd, word, end_key) {
    local
    FormatTime, timeStamp, , HH:mm:ss
    Send, % timeStamp
}

;;; Clipper method
PasteFromSlot(slot) {
    global clipper
    if (not clipper.clipsLoaded) {
        MsgBox, % "Clips not loaded. You must load them first."
        return
    }
	Gui MainGUI:Default
    RegExMatch(slot, "(\d)", slotnumber)
    fieldname := "ClipperP" . slotnumber
	GuiControlGet fieldvalue,, % fieldname
    Send % fieldvalue
}

;;; Editing helper
PreloadEditorWord() {
	global editor
    global engine
    global coach
	Gui MainGUI:Default
    ; Gui, Tab, Editor

    Gui, Show
    GuiControl, ChooseString, MainTabSet, Editor

    lastword := engine.record[engine.record.MaxIndex()]

    StringLower, loweredword, % lastword.word
    ; ControlFocus, , Qwertigraph
    GuiControl, Text, RegexWord, % loweredword
    GuiControl, Text, EditWord, % loweredword
    ; GuiControl, Focus, RegexWord

	editor.SearchMapEntries()

}


;;; Password handling methods
dailyKey := ""
desiredKeyLength := 40
GenerateKey(keylen) {
    Local
    key := ""
    Loop, %keylen% {
        Random, letter, 97, 122
        key := key . Chr(letter)
    }
    Return, key
}
Encrypt(plaintext) {
    global dailyKey
    global desiredKeyLength
    if ( dailyKey = "" ) {
        dailyKey := GenerateKey(desiredKeyLength)
    }
    Encrypted := ""
    Loop, Parse, plaintext
    {
        Encrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(dailyKey,A_Index,1))-32))+32)
    }

    Return Encrypted
}
Decrypt(cipherhash) {
    global dailyKey
    Decrypted := ""
    Loop, Parse, cipherhash
    {
        Decrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(dailyKey,A_Index,1))-32))+32)
    }
    Return Decrypted
}

stdna := ""
admna := ""
syana := ""
;;; methods for a standard username
InputStandardNapud() {
    global stdna
    global stdpud
    global engine
    engine.Stop()
    ; Default to the decrypted username when replacing the existing password 
    default_name := Decrypt(stdna)
    InputBox, stdna, Standard Name, Name, , , , , , , , %default_name%
    InputBox, stdpud, Standard PUD, PUD, HIDE
    engine.Start()
    stdna := Encrypt(stdna)
    stdpud := Encrypt(stdpud)
}
ResetStandardNapud() {
    global stdna
    global stdpud
    InputStandardNapud()
}
OutputStandardNapud() {
    global stdna
    global stdpud
    if (stdna == "") {
        InputStandardNapud()
    }
    Send % Decrypt(stdna)
    Send {Tab}
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(stdpud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
    ; Send % Decrypt(stdpud)
}
OutputStandardPud() {
    global stdna
    global stdpud
    if (stdna == "") {
        InputStandardNapud()
    }
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(stdpud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
}
;;; methods for an admin username
InputAdminNapud() {
    global admna
    global admpud
    global engine
    engine.Stop()
    ; Default to the decrypted username when replacing the existing password 
    default_name := Decrypt(admna)
    InputBox, admna, Admin Name, Name, , , , , , , , %default_name%
    InputBox, admpud, Admin PUD, PUD, HIDE
    engine.Start()
    admna := Encrypt(admna)
    admpud := Encrypt(admpud)
}
ResetAdminNapud() {
    global admna
    global admpud
    InputAdminNapud()
}
OutputAdminNapud() {
    global admna
    global admpud
    if (admna == "") {
        InputAdminNapud()
    }
    Send % Decrypt(admna)
    Send {Tab}
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(admpud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
    ; Send % Decrypt(admpud)
}
OutputAdminPud() {
    global admna
    global admpud
    if (admna == "") {
        InputAdminNapud()
    }
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(admpud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
    ; Send % Decrypt(admpud)
}
;;; methods for a service account
InputServiceAccountNapud() {
    global syana
    global syapud
    global engine
    default := syana
    engine.Stop()
    ; Default to the decrypted username when replacing the existing password 
    default_name := Decrypt(syana)
    InputBox, syana, Service Account Name, Name, , , , , , , , %default_name%
    InputBox, syapud, Service Account PUD, PUD, HIDE
    engine.Start()
    syana := Encrypt(syana)
    syapud := Encrypt(syapud)
}
ResetServiceAccountNapud() {
    global syana
    global syapud
    InputServiceAccountNapud()
}
OutputServiceAccountNapud() {
    global syana
    global syapud
    if (syana == "") {
        InputServiceAccountNapud()
    }
    Send % Decrypt(syana)
    Send {Tab}
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(syapud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
    ; Send % Decrypt(syapud)
}
OutputServiceAccountPud() {
    global syana
    global syapud
    if (syana == "") {
        InputServiceAccountNapud()
    }
    ; Must escape !+{}# characters in the password, or AHK will act upon the characters rather than print them  
    decrypted := Decrypt(syapud)
    decoded := RegExReplace(decrypted, "([!+{}#])", "{$1}")
    Send % decoded 
    ; Send % Decrypt(syapud)
}