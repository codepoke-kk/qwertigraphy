; ToDo
; Capitalization
; Add words that used to be in cmu 


#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

logFileDE := 0
LogVerbosityDE := 4
IfNotExist, logs
    FileCreateDir, logs

logEventDE(0, "not logged")
logEventDE(1, "not verbose")
logEventDE(2, "slightly verbose")
logEventDE(3, "pretty verbose")
logEventDE(4, "very verbose")

PersonalDataFolder := A_AppData "\Qwertigraph"
logEventDE(1, "Personal data found at " PersonalDataFolder)

dictionariesLoaded := 0
dictionaryListFile := PersonalDataFolder "\dictionary_load.list"
dictionaryDropDown := ""
dictionaryFullToShortNames := {}
dictionaryShortToFullNames := {}
logEventDE(1, "Loading dictionaries list from " dictionaryListFile)
dictionaries := []
Loop, read, %dictionaryListFile% 
{
    if (! RegexMatch(A_LoopReadLine, "^;")) {
        logEventDE(1, "Adding dictionary " A_LoopReadLine)
        personalizedDict := RegExReplace(A_LoopReadLine, "AppData", PersonalDataFolder) 
        dictionaries.Push(personalizedDict)
        dictShortName := RegExReplace(personalizedDict, "^(.*\\)", "")
        dictionaryFullToShortNames[personalizedDict] := dictShortName
        dictionaryDropDown := dictionaryDropDown "|" dictShortName 
        logEventDE(1, "Adding dictionary names " dictShortName " for " personalizedDict)
        dictionaryShortToFullNames[dictShortName] := personalizedDict
    } else {
        logEventDE(1, "Skipping dictionary " A_LoopReadLine)
    }
}

negationsFile := PersonalDataFolder "\negations.txt"
logEventDE(1, "Loading negations from " negationsFile)
negations := ComObjCreate("Scripting.Dictionary")
Loop,Read,%negationsFile%   ;read negations
{
    logEventDE(4, "Loading negation " A_LoopReadLine)
    negations.item(A_LoopReadLine) := 1
}

endkeys={backspace}{enter}{tab}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}{space}.,?!;:'"-_{{}{}}[]/\+=|{LButton}
last_end_key := ""
input_text_backspace_buffer := ""
last_input_text_backspace_buffer := ""
qwerds := CSobj()
words := {}
hints := {}
characters_typed_raw := 0
characters_typed_final := 0
time_taken := 0
average_raw_wpm := 1
average_final_wpm := 1
discard_ratio := .2

NumLines := 0
logEventDE(1, "Loading forms")
for index, dictionary in dictionaries
{
    logEventDE(1, "Loading dictionary " dictionary)
    Loop,Read,%dictionary%   ;read dictionary into array
    {
        NumLines:=A_Index-1
        IfEqual, A_Index, 1, Continue ; Skip title row
        Loop,Parse,A_LoopReadLine,CSV   ;parse line into 6 fields
        {
            field%A_Index% = %A_LoopField%
        }
        
        ; Create 3 forms of this word
        form := Object("dictionary", dictionary, "word", field1, "formal", field2, "lazy", field3, "keyer", field4, "usage", field5, "hint", field6)
       
        StringUpper, lazyUPPER, field3
        StringUpper, wordUPPER, field1
        formUPPER := Object("dictionary", dictionary, "word", wordUPPER, "formal", field2, "lazy", lazyUPPER, "keyer", field4, "usage", field5, "hint", field6)
        
        lazyCapped := SubStr(lazyUPPER, 1, 1) . SubStr(field3, 2, (StrLen(field3) - 1))
        wordCapped := SubStr(wordUPPER, 1, 1) . SubStr(field1, 2, (StrLen(field1) - 1))
        formCapped := Object("dictionary", dictionary, "word", wordCapped, "formal", field2, "lazy", lazyCapped, "keyer", field4, "usage", field5, "hint", field6)
        
        lazy := form.lazy
        logEventDE(4, "Creating qwerd " lazy)
        if ( not qwerds[lazy] ) {
            ; Make sure we don't overwrite an existing word with a less used version
            qwerds[lazy] := form
            qwerds[lazyUPPER] := formUPPER
            qwerds[lazyCapped] := formCapped
        }
        wordKey := form.word
        logEventDE(4, "Creating word " wordKey)
        if ( not words[wordKey] ) {
            ; Make sure we don't overwrite an existing word with a less used version
            words[wordKey] := form
        }
        hintKey := form.word
        logEventDE(4, "Creating hint " hintKey)
        if ( not hints[hintKey] ) {
            ; Make sure we don't overwrite an existing word with a less used version
            hints[hintKey] := form
        }
    }
    logEventDE(1, "Loaded dictionary " dictionary " resulting in " NumLines " forms")
}
logEventDE(1, "Loaded all forms")
dictionariesLoaded := 1

loop
 {
    ih := InputHook("VCE", endkeys)
    ;Msgbox, % "Backspace is " ih.BackspaceIsUndo
    ih.Start()
    input_start := A_TickCount
    ErrorLevel := ih.Wait()
    if (ErrorLevel = "EndKey") {
        ; Only react when the input is collected due to a stop key being pressed
        if (not InStr("{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{left}{up}{right}{down}", ih.EndKey)) {
            ; Only react when the input is collected due to a non-movement key
            ErrorLevel .= ":" ih.EndKey
            ExpandInput(ih.Input, ih.EndKey, ih.EndMods, (A_TickCount - input_start))
        }
    } 
 }
 
 
 ExpandInput(input_text, key, mods, ticks) {
  local
  global qwerds
  global hints
  global last_end_key
  global characters_typed_raw
  global characters_typed_final
  global time_taken
  global average_raw_wpm
  global average_final_wpm
  global discard_ratio
  global input_text_backspace_buffer
  global last_input_text_backspace_buffer
  
  logEventDE(4, "Expanding " input_text " ended with " key " after " ticks " millis")
  buffered_input_text := input_text_backspace_buffer . input_text
  logEventDE(4, "Input_text after buffering " buffered_input_text)
  
  if ((last_end_key == "'") and (InStr("s,d,t,m,re,ve,ll",buffered_input_text))) {
    final_characters_count := StrLen(buffered_input_text) + 1
    logEventDE(4, "Completed contraction " buffered_input_text)
  } else if (last_end_key == "-") {
    final_characters_count := StrLen(buffered_input_text) + 1
    logEventDE(4, "Completed hyphen " buffered_input_text)
  } else if (key = "backspace") {
    logEventDE(4, "Did a backspace after " buffered_input_text " buffering " input_text_backspace_buffer)
    if (buffered_input_text = "") {
        logEventDE(4, "Backspaced with an empty buffer. Retrieving last buffer " last_input_text_backspace_buffer)
        buffered_input_text := last_input_text_backspace_buffer
        input_text_backspace_buffer := last_input_text_backspace_buffer
        last_input_text_backspace_buffer := ""
    }
    input_text_backspace_buffer := SubStr(buffered_input_text, 1, (StrLen(buffered_input_text) - 1))
    final_characters_count := StrLen(buffered_input_text)
    logEventDE(4, "Did a backspace after " buffered_input_text " buffering " input_text_backspace_buffer)
  } else if (qwerds[buffered_input_text]) {
    if (not InStr(mods, "^")) {
      ;;; Expandable
      logEventDE(4, "Matched a qwerd " qwerds[buffered_input_text].word)
      final_characters_count := StrLen(qwerds[buffered_input_text].word) + 1
      ; expand this qwerd by first deleting the qwerd and the end character
      deleteChars := StrLen(buffered_input_text) + 1
      Send, {Backspace %deleteChars%}
      if (False) {
          StringUpper, word_upper, % qwerds[buffered_input_text].word
          qwerd_upper := SubStr(word_upper, 1, 1) . SubStr(qwerds[buffered_input_text].word, 2, (StrLen(qwerds[buffered_input_text].word) - 1))
          logEventDE(4, "Sending capitalized " qwerd_upper)
          Send, % qwerd_upper
      } else {
          logEventDE(4, "Sending lower " qwerds[buffered_input_text].word)
          Send, % qwerds[buffered_input_text].word
      }
      input_text_backspace_buffer := ""
      ;ExpandOutline(sent_text, qwerds[buffered_input_text].word, qwerds[buffered_input_text].formal, qwerds[buffered_input_text].saves, qwerds[buffered_input_text].power)
    } else {
      ; The control key was down, so just send the end char
      final_characters_count := StrLen(buffered_input_text) + 1
    }
    Send, {%key%}
  } else {
      ; This buffered input was not a special character, nor a qwerd
      ; Keep the buffer for later backspace tracking
      logEventDE(4, "Double buffering " input_text_backspace_buffer)
      last_input_text_backspace_buffer := input_text "+" 
      final_characters_count := StrLen(buffered_input_text) + 1
      logEventDE(4, "No match for " buffered_input_text ", so deleting " input_text_backspace_buffer)
      input_text_backspace_buffer := ""
      if (hints[buffered_input_text]) {
          ;;; Hintable
          logEventDE(4, "Matched a hint " hints[buffered_input_text])
          FlashHint(hints[buffered_input_text].hint)
      } else {
          ;;; Ignorable 
          logEventDE(4, "Unknown qwerd")
      }
  }
  
  if (key == "'") {
    last_end_key := key
  } else if (key == "-") {
    if (buffered_input_text = "") {
        last_end_key := key
    } else {
        last_end_key := ""
    }
  } else {
    last_end_key := ""
  }
  
  ; If there's not been a long pause, count this in the WPM tracking
  buffered_input_text_wpm := (StrLen(final_characters_count) / (ticks / 12000))
  if ((buffered_input_text_wpm / average_final_wpm) > discard_ratio) {
    characters_typed_raw += StrLen(buffered_input_text) + 1
    characters_typed_final += final_characters_count
    time_taken += ticks
    average_raw_wpm := Round(characters_typed_raw / (time_taken / 12000))
    average_final_wpm := Round(characters_typed_final / (time_taken / 12000))
    FlashHint(average_raw_wpm " WPM/" average_final_wpm " WPM")
  }
}

ExpandOutline(lazy, word, formal, saves, power) {
    logEventDE(4, "Expanded outline " lazy " as " word)
}

FlashHint(hint) {
    Tooltip %hint%, A_CaretX, A_CaretY + 30
    SetTimer, ClearToolTip, -1500
    return 

    ClearToolTip:
      ToolTip
    return 
}

CSobj() {
    static base := object("_NewEnum","__NewEnum", "Next","__Next", "__Set","__Setter", "__Get","__Getter")
    return, object("__sd_obj__", ComObjCreate("Scripting.Dictionary"), "base", base)
}
    __Getter(self, key) {
        return, self.__sd_obj__.item(key)
    }
    __Setter(self, key, value) {
        self.__sd_obj__.item(key) := value
        return, false
    }
    __NewEnum(self) {
        return, self
    }
    __Next(self, ByRef key = "", ByRef val = "") {
        static Enum
        if not Enum
            Enum := self.__sd_obj__._NewEnum
        if Not Enum[key], val:=self[key]
            return, Enum:=false
        return, true
    }


logEventDE(verbosity, message) {
    global logFileNameDE
    global logFileDE
    global LogVerbosityDE
    
    if (not verbosity) or (not LogVerbosityDE)
        Return
    FormatTime, logDateStamp, , yyyyMMdd.HHmmss
    if (! logFileDE) {
        logFileNameDE := "editor." . logDateStamp . ".log"
        logFileDE := FileOpen("logs\" logFileNameDE, "a")
        logFileDE.Write(logDateStamp . "[0]: Log initiated`r`n")
    }
    if (verbosity <= LogVerbosityDE) 
        logFileDE.Write(logDateStamp "[" verbosity "]: " message "`r`n")
}


; Stop input when the mouse buttons are clicked
~LButton::ih.Stop()
~RButton::ih.Stop()