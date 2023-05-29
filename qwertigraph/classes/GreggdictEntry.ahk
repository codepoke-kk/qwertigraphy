
class GreggdictEntry
{
    __New(line)
    {
        local fields
		line := StrReplace(line, """", "")
		fields := StrSplit(line, ",")
		this.word := fields[1]
		this.page := fields[2]
		this.link := fields[3]
		this.x := fields[4]
		this.y := fields[5]
    }
}
