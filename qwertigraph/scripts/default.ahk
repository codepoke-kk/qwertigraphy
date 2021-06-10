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
DraftFromChat() {
    local
    AutoTrim Off  ; Retain any leading and trailing whitespace on the clipboard.
    ClipboardOld := ClipboardAll
    Clipboard := ""  ; Must start off blank for detection to work.
    Send ^a
    Send ^c
    ClipWait 5
    if ErrorLevel { 
        ; ClipWait timed out.
        Msgbox, % "Wait ended on clipboard copy"
        return
    }
    conversation := Clipboard
    Clipboard := ClipboardOld  ; Restore previous contents of clipboard.

    players := {}
    lines := StrSplit(conversation, ["`n"])
    ; Msgbox % "Conversation is " conversation
    ; Msgbox % "Lines are " lines[1]
    for key, line in lines {
        FoundPos := RegExMatch(line, "O)\] (.*)\:", matches)
        if (FoundPos) {
            if (! players[matches.Value(1)]) {
                players[matches.Value(1)] := 1
            } else {
                players[matches.Value(1)]++
            }
        }
    }
    subject := ""
    for player, statements in players {
        subject .=  player " " statements ", "
    }
    subject := SubStr(subject,1,StrLen(subject)-2)

    olMailItem := 0
    MailItem := ComObjActive("Outlook.Application").CreateItem(olMailItem)
    MailItem.Subject := subject
    MailItem.Body := conversation
    MailItem.Display

    Send ^s
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