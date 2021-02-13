
class DictionaryEntry
{
    __New(line)
    {
		line := StrReplace(line, """", "")
		fields := StrSplit(line, ",")
		this.word := fields[1]
		this.form := fields[2]
		this.qwerd := fields[3]
		this.keyer := fields[4]
		this.usage := fields[5]
		this.hint := fields[6]
		this.dictionary := fields[7]
		this.saves := StrLen(this.word) - StrLen(this.qwerd)
		this.power := StrLen(this.word) / StrLen(this.qwerd)
		this.isPhrase := InStr(this.word, " ") > 0
		StringLower, loweredQwerd, % this.qwerd
		this.isLower := (loweredQwerd == this.qwerd)
    }
	
	generateHint() {
		return % this.word " = " this.qwerd " (" this.form ") [" this.saves "]"
	}
}
