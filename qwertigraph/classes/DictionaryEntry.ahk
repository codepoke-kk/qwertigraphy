
class DictionaryEntry
{
    __New(line)
    {
        local fields
		line := StrReplace(line, """", "")
		fields := StrSplit(line, ",")
		this.word := fields[1]
		this.form := fields[2]
		this.qwerd := fields[3]
		this.keyer := fields[4]
		this.chord := StrLen(fields[5]) ? fields[5] : ""
		this.usage := fields[6]
		this.dictionary := fields[7]
		this.reliability := (InStr(this.dictionary, "personal")) ? "^" : "" 
		this.reliability .= ((InStr(this.dictionary, "core")) or ((InStr(this.dictionary, "supplement")))) ? "+" : "" 
		this.reliability .= (InStr(this.dictionary, "cmu")) ? "?" : "" 
		this.hint := "-v1-"
		this.chordable := "Initializing"
		this.saves := StrLen(this.word) - StrLen(this.qwerd)
		this.power := StrLen(this.word) / StrLen(this.qwerd)
		this.isPhrase := InStr(this.word, " ") > 0
		StringLower, loweredQwerd, % this.qwerd
		this.isLower := (loweredQwerd == this.qwerd)
		StringUpper, upperedQwerd, % this.qwerd
		StringUpper, upperedWord, % this.word
		this.isUpper := (upperedQwerd == this.qwerd)
		this.isCapped := ((SubStr(upperedWord,1,1)) == (SubStr(this.word,1,1)))
		this.isProper := (((not this.isUpper) and (not this.isLower)) 
			or (this.isUpper and ((StrLen(this.word) == 1))) 
			or (this.isUpper and (InStr(this.word, "()"))) 
			or (this.isCapped and (StrLen(this.qwerd) == 1)))
    }
	
	generateHint() {
		return % this.word " = " this.qwerd " (" this.form ") [" this.saves "]"
	}
}
