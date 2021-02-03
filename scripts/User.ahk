desiredKeyLength := 40
#KeyHistory 500
SetKeyDelay, 50

; Make the pretty icon
I_Icon = unicycle.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%
;return

GenerateKey(keylen) {
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
    Loop, Parse, plaintext 
    {
        Encrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(dailyKey,A_Index,1))-32))+32)
    }
    
    Return Encrypted
}
Decrypt(cipherhash) {
    global dailyKey
    Loop, Parse, cipherhash 
    {
        Decrypted .= Chr(((Asc(A_LoopField)-32)^(Asc(SubStr(dailyKey,A_Index,1))-32))+32)
    }
    Return Decrypted
}

InputStandardNapud() {
    global stdna
    global stdpud
    InputBox, stdna, Standard Name, Name
    InputBox, stdpud, Standard PUD, PUD, HIDE
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
    InputBox, admna, Admin Name, Name
    InputBox, admpud, Admin PUD, PUD, HIDE
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
^#i::
    OutputStandardPud()
    Return
^#k::
    OutputStandardNapud()
    Return
^#o::
    OutputAdminPud()
    Return
^#l::
    OutputAdminNapud()
    Return