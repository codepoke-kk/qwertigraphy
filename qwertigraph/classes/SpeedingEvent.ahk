
class SpeedingEvent
{
    __New(when, ticks, in_chars, out_chars, endchar)
    {
		this.when := when
		this.ticks := ticks
		this.in_chars := in_chars
		this.out_chars := out_chars
		this.endchar := endchar
		
		; This will be used to ignore long pauses 
		this.wpm := (in_chars / (ticks / 12000))
		
		
		
		;if ((buffered_input_text_wpm / this.average_final_wpm) > this.discard_ratio) {
		;	this.characters_typed_raw += StrLen(buffered_input_text) + 1
		;	this.characters_typed_final += final_characters_count
		;	this.time_taken += ticks
		;	this.average_raw_wpm := Round(this.characters_typed_raw / (this.time_taken / 12000))
		;	this.average_final_wpm := Round(this.characters_typed_final / (this.time_taken / 12000))
		;	;FlashHint(average_raw_wpm " WPM/" average_final_wpm " WPM")
		;}
    }
}
