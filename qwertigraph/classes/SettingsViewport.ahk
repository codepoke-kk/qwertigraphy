
global SettingsLoggingLevelMap
global SettingsLoggingLevelEngine
global SettingsLoggingLevelEditor
global SettingsLoggingLevelCoach
global SettingsLoggingLevelPad

Gui, Tab, Settings
; Add regex search fields
Gui, Add, Text, x12  y64 w160 h20 , Logging Level Settings 
Gui, Add, Text, x12  y84 w160 h20 , Dictionary Map:
Gui, Add, Edit, x172  y84 w20 h20 vSettingsLoggingLevelMap gSettingsLoggingLevelMap, 1
Gui, Add, Text, x12  y104 w160 h20 , Expansion Engine:
Gui, Add, Edit, x172  y104 w20 h20 vSettingsLoggingLevelEngine gSettingsLoggingLevelEngine, 1
Gui, Add, Text, x12  y124 w160 h20 , Editor:
Gui, Add, Edit, x172  y124 w20 h20 vSettingsLoggingLevelEditor gSettingsLoggingLevelEditor, 1
Gui, Add, Text, x12  y144 w160 h20 , Coach:
Gui, Add, Edit, x172  y144 w20 h20 vSettingsLoggingLevelCoach gSettingsLoggingLevelCoach, 1
Gui, Add, Text, x12  y164 w160 h20 , Gregg Pad:
Gui, Add, Edit, x172  y164 w20 h20 vSettingsLoggingLevelPad gSettingsLoggingLevelPad, 1


SettingsLoggingLevelMap() {
	global map
	GuiControlGet SettingsLoggingLevelMap
	if (RegExMatch(SettingsLoggingLevelMap, "^[012345]$")) {
		map.logVerbosity := SettingsLoggingLevelMap
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelMap
	}
}
SettingsLoggingLevelEngine() {
	global engine
	GuiControlGet SettingsLoggingLevelEngine
	if (RegExMatch(SettingsLoggingLevelEngine, "^[012345]$")) {
		engine.logVerbosity := SettingsLoggingLevelEngine
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEngine
	}
}
SettingsLoggingLevelEditor() {
	global editor
	GuiControlGet SettingsLoggingLevelEditor
	if (RegExMatch(SettingsLoggingLevelEditor, "^[012345]$")) {
		editor.logVerbosity := SettingsLoggingLevelEditor
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEditor
	}
}
SettingsLoggingLevelCoach() {
	global coach
	GuiControlGet SettingsLoggingLevelCoach
	if (RegExMatch(SettingsLoggingLevelCoach, "^[012345]$")) {
		coach.logVerbosity := SettingsLoggingLevelCoach
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEngine
	}
}
SettingsLoggingLevelPad() {
	global pad
	GuiControlGet SettingsLoggingLevelPad
	if (RegExMatch(SettingsLoggingLevelPad, "^[012345]$")) {
		pad.logVerbosity := SettingsLoggingLevelPad
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelPad
	}
}