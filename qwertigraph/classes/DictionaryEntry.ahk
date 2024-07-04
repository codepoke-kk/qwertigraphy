
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
        
        ; Build upppered and lowered variables needed for isProper determination
		StringLower, loweredQwerd, % this.qwerd
		this.isLower := (loweredQwerd == this.qwerd)
		StringUpper, upperedQwerd, % this.qwerd
		StringUpper, upperedWord, % this.word
		this.isUpper := (upperedQwerd == this.qwerd)
        
        ; The Qwerd identifies affixes: Prefix and Suffix are marked in the qwerd with <>
        this.lastCharacter := SubStr(this.qwerd, 0)
        this.isPrefix := this.lastCharacter == ">"
        this.isSuffix := this.lastCharacter == "<"
        this.isAffix := this.isPrefix or this.isSuffix
        ; Prefixes and Suffixes optionally have a hyphen at beginning or end, but any word can have a hyphen
        ; Handling case for every option is not easy 
        ; Basically:
            ; Not all upper or lower because that means it's mixed case, so auto win
            ; or it's capped and the word is only 1 long because a proper and an upper cannot be distinguished
            ; or it's a code like b9 and not an affix because if I don't, my codes won't save 
            ; or the qwerd is 1 character long because a proper and an upper cannot be distinguished
        if (this.isAffix) {
            caseTestableWord := RegExReplace(this.word, "-")
            this.isCapped := ((SubStr(upperedWord,1,1)) == (SubStr(caseTestableWord,1,1)))
            this.isProper := (((not this.isUpper) and (not this.isLower))
                or (this.isUpper and ((StrLen(caseTestableWord) == 1)))
                or (this.isCapped and (StrLen(this.qwerd) == 2))) 
        } else {
            this.isCapped := ((SubStr(upperedWord,1,1)) == (SubStr(this.word,1,1)))
            this.isProper := (((not this.isUpper) and (not this.isLower))
                or (this.isUpper and ((StrLen(this.word) == 1)))
                or (this.isUpper and (RegexMatch(this.word, "[0-9()]")))
                or (this.isCapped and (StrLen(this.qwerd) == 1))) 
        }
		; If 1 or more but not all characters after the first is capitalized
		this.wordTail := SubStr(this.word,2,StrLen(this.word) - 1)
		StringLower, loweredWordTail, % this.wordTail
		this.isCamel := ((this.isProper) and (!(this.wordTail == loweredWordTail)))
    }

	generateHint() {
		return % this.word " = " this.qwerd " (" this.form ") [" this.saves "]"
	}
}
