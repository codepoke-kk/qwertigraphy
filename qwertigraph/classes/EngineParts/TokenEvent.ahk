
Class TokenEvent {

	__New(input, ender) {
		this.created := A_TickCount
		this.input := input
		this.ender := ender
		this.output := ""
		this.qwerd := ""
		this.backspaces := 0
		this.active_edited := false 
		this.deleted_characters := 0
		this.match := 0
		this.chorded := 0
		this.miss := 0
		this.other := 0
		
	}
}