
Class TokenEvent {

	__New(input, ender) {
		this.created := A_TickCount
		this.input := input
		this.endkey := ender
		this.output := ""
		this.backspaces := 0
		this.edited_output := false 
	}
}