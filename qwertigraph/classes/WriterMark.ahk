Class WriterMark {
	__New(x, y, dx, dy, dt, t) {
		this.x := x
		this.y := y 
		this.dx := dx
		this.dy := dy 
		this.dt := dt 
		this.t := t
		this.rads := 0 ; this.GetRads(dx, dy)
	}
	Serialize() {
		return this.x "," this.y "," this.dx "," this.dy "," this.dt "," this.t
	}
}