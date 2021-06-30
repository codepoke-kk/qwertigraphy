
global SettingsLoggingLevelMap
global SettingsLoggingLevelEngine
global SettingsLoggingLevelEditor
global SettingsLoggingLevelCoach
global SettingsLoggingLevelPad

Gui, Tab, Settings
; Add regex search fields
Gui, Add, Text, x12  y64 w444 h20 , Logging Level Settings (1 for low logging up to 4 for high logging)
Gui, Add, Text, x12  y84 w160 h20 , Dictionary Map:
Gui, Add, Edit, x172  y84 w20 h20 vSettingsLoggingLevelMap gSettingsLoggingLevelMap, % qenv.properties.LoggingLevelMap
Gui, Add, Text, x12  y104 w160 h20 , Expansion Engine:
Gui, Add, Edit, x172  y104 w20 h20 vSettingsLoggingLevelEngine gSettingsLoggingLevelEngine, % qenv.properties.LoggingLevelEngine
Gui, Add, Text, x12  y124 w160 h20 , Editor:
Gui, Add, Edit, x172  y124 w20 h20 vSettingsLoggingLevelEditor gSettingsLoggingLevelEditor, % qenv.properties.LoggingLevelEditor
Gui, Add, Text, x12  y144 w160 h20 , Coach:
Gui, Add, Edit, x172  y144 w20 h20 vSettingsLoggingLevelCoach gSettingsLoggingLevelCoach, % qenv.properties.LoggingLevelCoach
Gui, Add, Text, x12  y164 w160 h20 , Gregg Pad:
Gui, Add, Edit, x172  y164 w20 h20 vSettingsLoggingLevelPad gSettingsLoggingLevelPad, % qenv.properties.LoggingLevelPad

Gui, Add, Text, x12  y244 w444 h20 , Phrase suggestion enthusiasm (1 for low no recommendations to 4000+ for all of them)
Gui, Add, Text, x12  y264 w160 h20 , Enthusiasm:
Gui, Add, Edit, x172  y264 w40 h20 vSettingsPhraseEnthusiasm gSettingsPhraseEnthusiasm, % qenv.properties.PhraseEnthusiasm

Gui, Add, Text, x12  y324 w444 h20 , Chord release milliseconds window (10 for no chords to 100 for too many)
Gui, Add, Text, x12  y344 w160 h20 , Chord Window:
Gui, Add, Edit, x172  y344 w40 h20 vSettingsChordWindow gSettingsChordWindow, % qenv.properties.ChordWindow

Gui, Add, Text, x12  y404 w444 h20 , Coach-ahead delay milliseconds 
Gui, Add, Text, x12  y424 w160 h20 , Coach ahead delay:
Gui, Add, Edit, x172  y424 w40 h20 vSettingsCoachAheadWait gSettingsCoachAheadWait, % qenv.properties.CoachAheadWait
Gui, Add, Text, x12  y444 w444 h20 , Coaching tip duration milliseconds 
Gui, Add, Text, x12  y464 w160 h20 , Coach ahead duration:
Gui, Add, Edit, x172  y464 w40 h20 vSettingsCoachAheadTipDuration gSettingsCoachAheadTipDuration, % qenv.properties.CoachAheadTipDuration
Gui, Add, Text, x12  y484 w444 h20 , Coaching maximum number of vertical lines
Gui, Add, Text, x12  y504 w160 h20 , Coaching max line count:
Gui, Add, Edit, x172  y504 w40 h20 vSettingsCoachAheadLines gSettingsCoachAheadLines, % qenv.properties.CoachAheadLines

SettingsLoggingLevelMap() {
	global map
	global qenv
	GuiControlGet SettingsLoggingLevelMap
	if (RegExMatch(SettingsLoggingLevelMap, "^[012345]$")) {
		map.logVerbosity := SettingsLoggingLevelMap
		qenv.properties.LoggingLevelMap := SettingsLoggingLevelMap
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelMap
	}
}
SettingsLoggingLevelEngine() {
	global engine
	global qenv
	GuiControlGet SettingsLoggingLevelEngine
	if (RegExMatch(SettingsLoggingLevelEngine, "^[012345]$")) {
		if (RegExMatch(SettingsLoggingLevelEngine, "4")) {
			Msgbox, % "Be aware. An engine log setting of 4 can display passwords as log entries"
		}
		engine.logVerbosity := SettingsLoggingLevelEngine
		qenv.properties.LoggingLevelEngine := SettingsLoggingLevelEngine
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEngine
	}
}
SettingsLoggingLevelEditor() {
	global editor
	global qenv
	GuiControlGet SettingsLoggingLevelEditor
	if (RegExMatch(SettingsLoggingLevelEditor, "^[012345]$")) {
		editor.logVerbosity := SettingsLoggingLevelEditor
		qenv.properties.LoggingLevelEditor := SettingsLoggingLevelEditor
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEditor
	}
}
SettingsLoggingLevelCoach() {
	global coach
	global qenv
	GuiControlGet SettingsLoggingLevelCoach
	if (RegExMatch(SettingsLoggingLevelCoach, "^[012345]$")) {
		coach.logVerbosity := SettingsLoggingLevelCoach
		qenv.properties.LoggingLevelCoach := SettingsLoggingLevelCoach
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelEngine
	}
}
SettingsLoggingLevelPad() {
	global pad
	global qenv
	GuiControlGet SettingsLoggingLevelPad
	if (RegExMatch(SettingsLoggingLevelPad, "^[012345]$")) {
		pad.logVerbosity := SettingsLoggingLevelPad
		qenv.properties.LoggingLevelPad := SettingsLoggingLevelPad
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsLoggingLevelPad
	}
}
SettingsPhraseEnthusiasm() {
	global coach
	global qenv
	GuiControlGet SettingsPhraseEnthusiasm
	if (RegExMatch(SettingsPhraseEnthusiasm, "^\d+$")) {
		coach.phrasePowerThreshold := SettingsPhraseEnthusiasm
		qenv.properties.PhraseEnthusiasm := SettingsPhraseEnthusiasm
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsPhraseEnthusiasm
	}
}
SettingsChordWindow() {
	global engine
	global qenv
	GuiControlGet SettingsChordWindow
	if (RegExMatch(SettingsChordWindow, "^\d+$")) {
		engine.keyboard.ChordReleaseWindow := SettingsChordWindow
        engine.setKeyboardChordWindowIncrements()
		qenv.properties.ChordWindow := SettingsChordWindow
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsChordWindow
	}
}
SettingsCoachAheadWait() {
	global engine
	global qenv
	GuiControlGet SettingsCoachAheadWait
	if (RegExMatch(SettingsCoachAheadWait, "^\d+$")) {
		engine.keyboard.CoachAheadWait := SettingsCoachAheadWait
		qenv.properties.CoachAheadWait := SettingsCoachAheadWait
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsCoachAheadWait
	}
}
SettingsCoachAheadTipDuration() {
	global engine
	global qenv
	GuiControlGet SettingsCoachAheadTipDuration
	if (RegExMatch(SettingsCoachAheadTipDuration, "^\d+$")) {
		engine.keyboard.CoachAheadTipDuration := SettingsCoachAheadTipDuration
		qenv.properties.CoachAheadTipDuration := SettingsCoachAheadTipDuration
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsCoachAheadTipDuration
	}
}
SettingsCoachAheadLines() {
	global engine
	global qenv
	GuiControlGet SettingsCoachAheadLines
	if (RegExMatch(SettingsCoachAheadLines, "^\d+$")) {
		engine.keyboard.CoachAheadLines := SettingsCoachAheadLines
		qenv.properties.CoachAheadLines := SettingsCoachAheadLines
		qenv.saveProperties()
	} else {
		Msgbox, % "Could not understand " SettingsChordWindow
	}
}
