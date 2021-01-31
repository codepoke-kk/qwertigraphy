
class LoggingEvent
{
	where := ""
	when := ""
	what := ""
	how := 0
	
	__New(where, when, what, how)
	{
		this.where := where 
		this.when := when 
		this.what := what 
		this.how := how 
	}
}
