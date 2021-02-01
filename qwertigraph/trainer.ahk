#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

#Include classes\QwertigraphyEnvironment.ahk
#Include classes\DictionaryEntry.ahk
#Include classes\DictionaryMap.ahk
#Include classes\MappingEngine_InputHook.ahk
#Include classes\Queue.ahk
#Include classes\LogViewport.ahk
#Include classes\LoggingEvent.ahk
#Include classes\SpeedingEvent.ahk
#Include classes\SpeedViewport.ahk
#Include classes\QwertigraphyEnvironment.ahk

; Make the pretty icon
I_Icon = coach.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%

qenv := new QwertigraphyEnvironment()
map := new DictionaryMap(qenv)
engine := new MappingEngine_InputHook(map)

logViewer := new LogViewport()
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(engine.logQueue)
		
speedViewer := new SpeedViewport()
speedViewer.addQueue(engine.speedQueue)
		
coachViewer := new CoachViewport()
coachViewer.addQueue(engine.coachQueue)


engine.Start()

#Include personal.ahk

class CoachingEvent 
{
	word := ""
	qwerd := ""
	hint := ""
	saves := 0
	power := 0
	match := 0
	miss := 0
	unknown := 0
	
	__New()
	{
	}
}

class CoachViewport
{
}




^Space::
^Enter::
^.::
^,::
^/::
^;::
^[::
	Send, % "{" SubStr(A_ThisHotkey, 2, StrLen(A_ThisHotkey) - 1) "}"
	return