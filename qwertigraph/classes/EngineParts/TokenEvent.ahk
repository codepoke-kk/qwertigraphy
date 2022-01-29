
Class TokenEvent {

	__New(input, ender) {
		this.created := A_TickCount
        this.index := -1
        this.method := "none"
		this.input := input
		this.ender := ender
		this.output := ""
		this.qwerdobject := ""
		this.backspaces := 0
		this.active_edited := false 
		this.deleted_characters := 0
        ; coach + dashboard
		this.qwerd := ""
		this.word := ""
		this.form := ""
		this.chord := ""
		this.match := 0
		this.cmatch := 0
		this.chorded := 0
		this.miss := 0
		this.other := 0
		this.ink := "red"
        ; speed
        this.in_chars := 0
        this.out_chars := 0
        this.ticks := 0
		
	}
}