#NoEnv
#Warn
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
CoordMode, ToolTip, Relative
setworkingdir, %a_scriptdir%

;engine := 0 ; Need the variable

OnExit("ExitFunc")

IfNotExist, dictionaries
    FileCreateDir, dictionaries
IfNotExist, strokepaths
    FileCreateDir, strokepaths
IfNotExist, templates
    FileCreateDir, templates
FileInstall, dictionaries\anniversary_core.csv, dictionaries\anniversary_core.csv, true
FileInstall, dictionaries\anniversary_supplement.csv, dictionaries\anniversary_supplement.csv, true
FileInstall, dictionaries\anniversary_supplement_corrected_d_ending.csv, dictionaries\anniversary_supplement_corrected_d_ending.csv, true
FileInstall, dictionaries\anniversary_phrases.csv, dictionaries\anniversary_phrases.csv, true
FileInstall, dictionaries\anniversary_modern.csv, dictionaries\anniversary_modern.csv, true
FileInstall, dictionaries\anniversary_cmu.csv, dictionaries\anniversary_cmu.csv, true
FileInstall, strokepaths\gregg.esv, strokepaths\gregg.esv, true
FileInstall, templates\dictionary_load.template, templates\dictionary_load.template, true
FileInstall, templates\negations.template, templates\negations.template, true
FileInstall, templates\personal.template, templates\personal.template, true
FileInstall, templates\retrains.template, templates\retrains.template, true
FileInstall, templates\personal_functions.template, templates\personal_functions.template, true
FileInstall, coach.ico, coach.ico, true

Gui, MainGUI: Add, Tab3,x6 y40 w928 h526 vMainTabSet, Coach|Historical|Editor|GreggDict|Logs||Settings|Strokes|Clipper|Player
Gui, MainGUI: Show, x262 y118 w940 h570, % "Qwertigraph"

#Include classes\Gdip_All.ahk
#Include classes\QwertigraphyEnvironment.ahk
#Include classes\DictionaryEntry.ahk
#Include classes\DictionaryMap.ahk
#Include classes\MappingEngine.ahk
#Include classes\AuxKeyboardEngine.ahk
#Include classes\Queue.ahk
#Include classes\LoggingEvent.ahk
#Include classes\LogViewport.ahk
#Include classes\SpeedingEvent.ahk
#Include classes\SpeedViewport.ahk
#Include classes\CoachingEvent.ahk
#Include classes\GreggdictViewport.ahk
#Include classes\GreggdictEntry.ahk
#Include classes\CoachViewport.ahk
#Include classes\EditorViewport.ahk
;#Include classes\PenEvent.ahk
;#Include classes\PadViewport.ahk
#Include classes\DashboardEvent.ahk
#Include classes\DashboardViewport.ahk
#Include classes\StrokepathsViewport.ahk
#Include classes\ClipperViewport.ahk
#Include classes\PlayerViewport.ahk
#Include scripts\shared_functions.ahk

; Make the pretty icon
I_Icon = coach.ico
IfExist, %I_Icon%
Menu, Tray, Icon, %I_Icon%

qenv := new QwertigraphyEnvironment()

#Include *i % qenv.personalDataFolder "\" personal_functions.ahk
map := new DictionaryMap(qenv)
aux := new AuxKeyboardEngine()
engine := new MappingEngine(map, aux)
aux.engine := engine

speedViewer := new SpeedViewport()
speedViewer.addQueue(engine.speedQueue)

coach := new CoachViewport(map, speedViewer)
coach.addQueue(engine.coachQueue)

greggdict := new GreggdictViewport(qenv)

editor := new EditorViewport(map,engine)
qenv.editor := editor

;greggpad := new PadViewport(qenv, engine.penQueue)
dashboard := new DashboardViewport(qenv, engine)
speedViewer.dashboard := dashboard
engine.dashboard := dashboard
aux.dashboard := dashboard
stroker := new StrokepathsViewport(qenv, dashboard)
player := new PlayerViewport(engine)
clipper := new ClipperViewport(qenv)
clipper.initialize()

logViewer := new LogViewport(qenv)
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(aux.logQueue)
logViewer.addQueue(engine.logQueue)
logViewer.addQueue(engine.keyboard.logQueue)
logViewer.addQueue(engine.listener.logQueue)
logViewer.addQueue(engine.accumulator.logQueue)
logViewer.addQueue(engine.serialsender.logQueue)
logViewer.addQueue(engine.chordsender.logQueue)
logViewer.addQueue(engine.expander.logQueue)
logViewer.addQueue(engine.sender.logQueue)
logViewer.addQueue(engine.coacher.logQueue)
logViewer.addQueue(coach.logQueue)
logViewer.addQueue(greggdict.logQueue)
logViewer.addQueue(editor.logQueue)
;logViewer.addQueue(greggpad.logQueue)
logViewer.addQueue(dashboard.logQueue)
logViewer.addQueue(stroker.logQueue)
logViewer.addQueue(clipper.logQueue)
;

#Include classes\SettingsViewport.ahk

engine.Start()

#Include *i personal.ahk


ExitFunc(ExitReason, ExitCode)
{
   global
   ; gdi+ may now be shutdown on exiting the program

   fh := logviewer.logFileHandle
   fh.WriteLine("Shutdown initiating at " A_Now)
   Gdip_Shutdown(dashboard.pToken)
   fh.WriteLine("Gdip shut down at " A_Now)
   Sleep, 30
   engine.Stop()
   fh.WriteLine("engine stopped at " A_Now)
   Sleep, 30
   engine := ""
   fh.WriteLine("engine shut down at " A_Now)
   Sleep, 30
   dashboard := ""
   fh.WriteLine("dashboard shut down at " A_Now)
   Sleep, 30
   editor := ""
   fh.WriteLine("editor shut down at " A_Now)
   Sleep, 150
   ; Msgbox, % "Shut down GDIP"
}

; Stop input when the mouse buttons are clicked
~LButton::
~RButton::
    engine.ResetInput()
    Return


; Enable/Disable
!#f::
    dashboard.ExposeDashboard("right")
    Return
!#p::
    engine.Stop()
    ; Msgbox, % "Chorder stopped Engine"
    Pause toggle
    Return
!#;::
    Pause toggle
    engine.Start()
    ; Msgbox, % "Chorder started Engine"
    Return
!#o::
    aux.Stop()
    Return
!#l::
    aux.Start()
    Return
!#d::
	Gui MainGUI:Default
	GuiControlGet SettingsDashboardShow
    newShowSetting := (RegExMatch(SettingsDashboardShow, "^0$")) ? 1 : 0
    GuiControl, Text, SettingsDashboardShow, %newShowSetting%
    dashboard.show := newShowSetting
    dashboard.ShowHide()
    qenv.properties.DashboardShow := newShowSetting
    qenv.saveProperties()
    Return
f10::
    WinMove,A,,3,3,1690,1000
    Return 
Insert::Backspace
NumpadIns::Backspace