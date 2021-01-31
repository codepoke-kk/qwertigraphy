; Adapted from Lexikos on the AutoHotkey forufor
; https://autohotkey.com/board/topic/70507-object-array-within-a-class/
class Queue
{
	name := ""
	__New(name) 
	{
		this.name := name
	}
    getSize() {
        i := this.MaxIndex()
        return i="" ? 0 : i
    }
    enqueue(value) {
        this.Insert(value)
        return this.MaxIndex()
    }
    dequeue() {
        return this.Remove(1)
    }
}
