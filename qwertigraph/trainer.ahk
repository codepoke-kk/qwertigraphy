#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

IfNotExist, dictionaries
    FileCreateDir, dictionaries
IfNotExist, templates
    FileCreateDir, templates
FileInstall, dictionaries\anniversary_core.csv, dictionaries\anniversary_core.csv, true
FileInstall, dictionaries\anniversary_supplement.csv, dictionaries\anniversary_supplement.csv, true
FileInstall, dictionaries\anniversary_phrases.csv, dictionaries\anniversary_phrases.csv, true
FileInstall, dictionaries\anniversary_modern.csv, dictionaries\anniversary_modern.csv, true
FileInstall, dictionaries\anniversary_cmu.csv, dictionaries\anniversary_cmu.csv, true
FileInstall, templates\dictionary_load.template, templates\dictionary_load.template, true
FileInstall, templates\negations.template, templates\negations.template, true
FileInstall, templates\personal.template, templates\personal.template, true
FileInstall, templates\retrains.template, templates\retrains.template, true
FileInstall, coach.ico, coach.ico, true

Gui, Add, Tab3,x6 y40 w928 h526, Coach|Editor|Logs|GreggPad|Settings
Gui, Show, x262 y118 w940 h570, % "Qwertigraph Trainer"

#Include classes\QwertigraphyEnvironment.ahk
#Include classes\DictionaryEntry.ahk
#Include classes\DictionaryMap.ahk
#Include classes\MappingEngine_InputHookL0.ahk
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
engine := new MappingEngine_InputHookL0(map)
		
speedViewer := new SpeedViewport()
speedViewer.addQueue(engine.speedQueue)
		
coach := new CoachViewport(map, speedViewer)
coach.addQueue(engine.coachQueue)

editor := new EditorViewport(map)

pad := new PadViewport(engine.penQueue)

logViewer := new LogViewport()
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(engine.logQueue)
logViewer.addQueue(coach.logQueue)
logViewer.addQueue(editor.logQueue)
logViewer.addQueue(pad.logQueue)
;

#Include classes\SettingsViewport.ahk

engine.Start()

#Include *i personal.ahk


; Stop input when the mouse buttons are clicked
~LButton::engine.ResetInput()
~RButton::engine.ResetInput()


; Enable/Disable
^#p::
    Pause toggle
    engine.ResetInput()
    Return

^Space::
^Enter::
^NumPadEnter::
^Tab::
^.::
^,::
^/::
^;::
^[::
	Send, % "{" SubStr(A_ThisHotkey, 2, StrLen(A_ThisHotkey) - 1) "}"
	Return
	

ContextEditForm:
EditorLVContextEditForm:
	Msgbox, % "Hit"
	