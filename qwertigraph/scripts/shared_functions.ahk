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
	Gui MainGUI:Default 
    RegExMatch(slot, "(\d)", slotnumber)
    fieldname := "ClipperP" . slotnumber
	GuiControlGet fieldvalue,, % fieldname
    Send % fieldvalue
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
InputStandardNapud() {
    global stdna
    global stdpud
    global engine
    engine.Stop()
    InputBox, stdna, Standard Name, Name
    InputBox, stdpud, Standard PUD, PUD, HIDE
    engine.Start()
    stdna := Encrypt(stdna)
    stdpud := Encrypt(stdpud)
}
OutputStandardNapud() {
    global stdna
    global stdpud
    if (stdna == "") {
        InputStandardNapud()
    }
    Send % Decrypt(stdna)
    Send {Tab}
    Send % Decrypt(stdpud)
}
OutputStandardPud() {
    global stdna
    global stdpud
    if (stdna == "") {
        InputStandardNapud()
    }
    Send % Decrypt(stdpud)
}
InputAdminNapud() {
    global admna
    global admpud
    global engine
    engine.Stop()
    InputBox, admna, Admin Name, Name
    InputBox, admpud, Admin PUD, PUD, HIDE
    engine.Start()
    admna := Encrypt(admna)
    admpud := Encrypt(admpud)
}
OutputAdminNapud() {
    global admna
    global admpud
    if (admna == "") {
        InputAdminNapud()
    }
    Send % Decrypt(admna)
    Send {Tab}
    Send % Decrypt(admpud)
}
OutputAdminPud() {
    global admna
    global admpud
    if (admna == "") {
        InputAdminNapud()
    }
    Send % Decrypt(admpud)
}