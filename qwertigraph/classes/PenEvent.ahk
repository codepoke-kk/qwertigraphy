
class PenEvent
{
	form := ""
	qwerd := ""
	word := ""
    ink := "blue"
	
	__New(form, qwerd, word, ink)
	{
		this.form := form 
		this.qwerd := qwerd 
		this.word := word 
        if (ink) {
            this.ink := ink
        }
	}
}
