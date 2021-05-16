desiredKeyLength := 40
#KeyHistory 500
SetKeyDelay, 40

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
!#i::
    OutputStandardPud()
    Return
!#k::
    Send, !#p
    OutputStandardNapud()
    SetTimer, ReenableQwertigraph, 4000
    Return
!#o::
    OutputAdminPud()
    Return
!#l::
    Send, !#p
    OutputAdminNapud()
    SetTimer, ReenableQwertigraph, 4000
    Return
    
ReenableQwertigraph:
    Send, !#p
    SetTimer, , Off
    Return 

!#d::
    FormatTime, dateStamp, , MM/dd/yyyy
    Send, % dateStamp
    Return
!#t::
    FormatTime, timeStamp, , HH:mm:ss
    Send, % timeStamp
    Return
    
; This function selects all the text in the focused window and copies it 
; It then parses that text looking for Skype comments
; You'll see below that it's called when you hit Ctrl-Win-S
!#s:: 
    AutoTrim Off  ; Retain any leading and trailing whitespace on the clipboard.
    ClipboardOld := ClipboardAll
    Clipboard := ""  ; Must start off blank for detection to work.
    Send ^a
    Send ^c
    ClipWait 1
    if ErrorLevel  ; ClipWait timed out.
        return

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

    Return


StringJoin(array, delimiter = ",")
{
  Loop
    If Not %array%%A_Index% Or Not t .= (t ? delimiter : "") %array%%A_Index%
      Return t
}

; Make the number pad + key a delete button 
NumpadAdd:: Send {bs}
^NumpadAdd:: Send {Ctrl down}{bs}{Ctrl up}
