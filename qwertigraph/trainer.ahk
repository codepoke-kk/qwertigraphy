#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

Gui, Add, Tab3,x6 y40 w928 h526, Coach|Editor|Logs|GreggPad
Gui, Show, x262 y118 w940 h570, % "Qwertigraph Trainer"

#Include classes\QwertigraphyEnvironment.ahk
#Include classes\DictionaryEntry.ahk
#Include classes\DictionaryMap.ahk
#Include classes\MappingEngine_InputHook.ahk
#Include classes\Queue.ahk
#Include classes\LoggingEvent.ahk
#Include classes\LogViewport.ahk
#Include classes\SpeedingEvent.ahk
#Include classes\SpeedViewport.ahk
#Include classes\CoachingEvent.ahk
#Include classes\CoachViewport.ahk
#Include classes\EditorViewport.ahk
#Include classes\PenEvent.ahk
#Include classes\PadViewport.ahk
#Include classes\QwertigraphyEnvironment.ahk

; Make the pretty icon
I_Icon = coach.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%

qenv := new QwertigraphyEnvironment()
map := new DictionaryMap(qenv)
engine := new MappingEngine_InputHook(map)
		
speedViewer := new SpeedViewport()
speedViewer.addQueue(engine.speedQueue)
		
coachViewer := new CoachViewport(map)
coachViewer.addQueue(engine.coachQueue)

editor := new EditorViewport(map)

pad := new PadViewport(engine.penQueue)

logViewer := new LogViewport()
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(engine.logQueue)
logViewer.addQueue(editor.logQueue)
logViewer.addQueue(pad.logQueue)
;

engine.Start()

#Include *i personal.ahk


; Stop input when the mouse buttons are clicked
~LButton::engine.ResetInput()
~RButton::engine.ResetInput()

^Space::
^Enter::
^Tab::
^.::
^,::
^/::
^;::
^[::
	Send, % "{" SubStr(A_ThisHotkey, 2, StrLen(A_ThisHotkey) - 1) "}"
	return
	

ContextEditForm:
EditorLVContextEditForm:
	msgbox, % "Hit"