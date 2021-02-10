#NoEnv 
#Warn 
#SingleInstance Force
SetBatchLines, -1
SetKeyDelay, -1
process, priority, ,high
coordmode, mouse, screen
setworkingdir, %a_scriptdir%

Gui, Add, Tab3,x6 y40 w928 h526, Coach|Editor|GreggPad|Logs
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

logViewer := new LogViewport()
logViewer.addQueue(qenv.logQueue)
logViewer.addQueue(map.logQueue)
logViewer.addQueue(engine.logQueue)
;logViewer.addQueue(editor.logQueue)
;
;editor := new EditViewport(map)

engine.Start()

#Include *i personal.ahk

global EditorTitle
global FormsLV
global RegexDict
global RegexWord
global RegexForm
global RegexQwerd
global RegexKeyer
global RegexUsage
global RegexHint
global EditDict
global EditWord
global EditForm
global EditQwerd
global EditKeyer
global EditUsage
global EditHint
global EditForm
global AutoGenHints
global SaveDictionaries
global DictionaryDropDown
global SaveProgress
global BackupCount
class EditViewport
{
	map := ""
	logQueue := new Queue("EditorQueue")
	logVerbosity := 4
	keyers := Array("","o","u","i","e","a","w","y")
	
	__New(map)
	{
		this.map := map
		DictionaryDropDown := map.dictionaryPickList
		
		Gui EditorGUI:Default
		; Add header text
		Gui, Add, Text, x12  y9 w700  h20 , Snazzy dictionary edits are more fun than Excel spreadsheet editing
		
		; Add regex search fields
		Gui, Add, Edit, -WantReturn x12  y29 w160 h20 vRegexWord,  
		Gui, Add, Edit, -WantReturn x172 y29 w90  h20 vRegexForm,  
		Gui, Add, Edit, -WantReturn x262 y29 w90  h20 vRegexQwerd, 
		Gui, Add, Edit, -WantReturn x352 y29 w30  h20 vRegexKeyer, 
		Gui, Add, Edit, -WantReturn x382 y29 w60  h20 vRegexUsage,  
		Gui, Add, Edit, -WantReturn x442 y29 w160 h20 vRegexHint, 
		Gui, Add, Edit, -WantReturn x602 y29 w210 h20 vRegexDict, 
		Gui, Add, Button, Default x812 y29 w90 h20 hwndhSearchMapEntries, Search
		this.hSearchMapEntries := hSearchMapEntries
		OnMessage(0x111, this.WmCommand := this.WmCommand.bind(this), 2)
		
		; Add the data ListView
		Gui, Add, ListView, x12 y49 w800 h420 vFormsLV hwndhListView, Word|Form|Qwerd||Keyer|Usage|Hint|Dictionary
		this.hListView := hListView
		LV_ModifyCol(5, "Integer")  ; For sorting, indicate that the Usage column is an integer.
		LV_ModifyCol(1, 160)
		LV_ModifyCol(2, 90)
		LV_ModifyCol(3, 90)
		LV_ModifyCol(4, 30)
		LV_ModifyCol(5, 60)
		LV_ModifyCol(6, 160)
		LV_ModifyCol(7, 180) ; 3 pixels short to avoid the h_scrollbar 
		
		; Add edit fields and controls
		Gui, Add, Edit, x12  y469 w160 h20 vEditWord,  
		Gui, Add, Edit, x172 y469 w70  h20 vEditForm,  
		Gui, Add, Button, x242 y469 w20 h20 hwndhAutoQwerdForm, L> 
		this.hAutoQwerdForm := hAutoQwerdForm
		Gui, Add, Edit, x262 y469 w90  h20 vEditQwerd, 
		Gui, Add, Button, x352 y469 w20 h20 hwndhAutoKey, K> 
		this.hAutoKey := hAutoKey
		Gui, Add, Edit, x372 y469 w30  h20 vEditKeyer, 
		Gui, Add, Edit, x402 y469 w50  h20 vEditUsage,  
		Gui, Add, Edit, x452 y469 w150 h20 vEditHint, 
		Gui, Add, DropDownList, x602 y469 w210 r5 vEditDict, %dictionaryDropDown%
		;Gui, Add, Button, x812 y469 w90 h20 gCommitEdit, Commit
		;Gui, Add, Button, x812 y500 w90 h30 gSaveDictionaries vSaveDictionaries Disabled, Save
		;Gui, Add, Progress, x12 y545 w700 h5 cOlive vSaveProgress, 1
		
		; Add checkbox controls
		;Gui, Add, CheckBox, x815 y49 w130 h20 vAutoGenHints gAutoGenHints Checked, AutoGenerate Hints
		;Gui, Add, Button, x812 y444 w90 h20 gOpenPersonalizations, Personalizations
		Gui, Add, Edit, x815 y74 w20 h20 vBackupCount, 2
		Gui, Add, Text, x840 y74 w105 h20, Backups to retain 
		
		; Create a popup menu to be used as the context menu:
		;Menu, FormsLVContextMenu, Add, Edit, hwndhContextEditForm
		;this.hContextEditForm := hContextEditForm
		;Menu, FormsLVContextMenu, Add, Delete, ContextDeleteForm
		;Menu, FormsLVContextMenu, Add, Add 's', ContextAddToForm_S
		;Menu, FormsLVContextMenu, Add, Add 'g', ContextAddToForm_G
		;Menu, FormsLVContextMenu, Add, Add 'd', ContextAddToForm_D
		;Menu, FormsLVContextMenu, Add, Add 't', ContextAddToForm_T
		;Menu, FormsLVContextMenu, Add, Add 'r', ContextAddToForm_R
		;Menu, FormsLVContextMenu, Add, Add 'ly', ContextAddToForm_LY
		;Menu, FormsLVContextMenu, Default, Edit  ; Make "Edit" a bold font to indicate that double-click does the same thing.
		
		; Generated using SmartGUI Creator 4.0
		Gui, Show, x262 y118 h560 w936, Qwertigraphy Dictionary Editor
	}
 
 	WmCommand(wParam, lParam){
		; the "h" variables are unique numbers for each Windows event listener. Bind a listener to a function 
		this.logEvent(3, "A button was clicked " wParam "!!" lParam)
		if (lParam = this.hSearchMapEntries) {
			this.SearchMapEntries()
		} else if (lParam = this.hAutoQwerdForm) {
			this.SearchMapEntries()
		} else if (lParam = this.hAutoKey) {
			this.SearchMapEntries()
		} else if (lParam = this.hListView) {
			this.listViewEvent()
		} else {
			this.logEvent(2, "We did not understand this event!")
		}
	}
	
	listViewEvent() {
		Gui EditorGUI:Default
		this.logEvent(2, "Listview event " A_GuiEvent " on " A_EventInfo)
		if (A_GuiEvent = "DoubleClick") {
			this.prepareEdit(A_EventInfo)
		}
		if (A_GuiEvent = "e") {
			LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
			this.logEvent(3, "Listview in-place edit to  " RowText)
			Msgbox, % "You edited row " A_EventInfo " to: " RowText
		}
	}
	
	prepareEdit(EventInfo) {
		Msgbox, % "Prepare edit " EventInfo " to: " RowText
	}
	
	SearchMapEntries() {
		Gui EditorGUI:Default
		GuiControlGet RegexDict
		GuiControlGet RegexWord
		GuiControlGet RegexForm
		GuiControlGet RegexQwerd
		GuiControlGet RegexKeyer
		GuiControlGet RegexUsage
		GuiControlGet RegexHint
		
		;global SaveProgress
		
		
		this.logEvent(3, "RegexWord " RegexWord ", RegexForm " RegexForm ", RegexQwerd " RegexQwerd ", RegexKeyer " RegexKeyer ", RegexUsage " RegexUsage ", RegexHint " RegexHint ", RegexDict " RegexDict )
		
		requiredMatchCount := 0
		requiredMatchCount += (RegexWord) ? 1 : 0
		requiredMatchCount += (RegexForm) ? 1 : 0
		requiredMatchCount += (RegexQwerd) ? 1 : 0
		requiredMatchCount += (RegexKeyer) ? 1 : 0
		requiredMatchCount += (RegexUsage) ? 1 : 0
		requiredMatchCount += (RegexHint) ? 1 : 0
		requiredMatchCount += (RegexDict) ? 1 : 0
		foundKeys := {}
		for qwerdKey, garbage in this.map.qwerds {
			StringLower, qwerdKey, qwerdKey
			if (foundKeys[qwerdKey]) {
				; Must be case insensitive in this searching 
				continue
			}
			qwerd := this.map.qwerds.item(qwerdKey)
			if (RegexDict) {
				if (RegExMatch(qwerd.dictionary,RegexDict)) {
					this.logEvent(4, "RegexDict matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexWord) {
				if (RegExMatch(qwerd.word,RegexWord)) {
					this.logEvent(4, "RegexWord matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexForm) {
				if (RegExMatch(qwerd.form,RegexForm)) {
					this.logEvent(4, "RegexForm matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexQwerd) {
				if (RegExMatch(qwerd.qwerd,RegexQwerd)) {
					this.logEvent(4, "RegexQwerd matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexKeyer) {
				if (RegExMatch(qwerd.keyer,RegexKeyer)) {
					this.logEvent(4, "RegexKeyer matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexUsage) {
				if (RegExMatch(qwerd.usage,RegexUsage)) {
					this.logEvent(4, "RegexUsage matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
			if (RegexHint) {
				if (RegExMatch(qwerd.hint,RegexHint)) {
					this.logEvent(4, "RegexHint matched " qwerdKey)
					foundKeys[qwerdKey] := (foundKeys[qwerdKey]) ? foundKeys[qwerdKey] + 1 : 1
				}
			}
		}
		
		LV_Delete()
		for foundKey, count in foundKeys {
			if (foundKeys[foundKey] = requiredMatchCount) {
				qwerd := this.map.qwerds.item(foundKey)
				LV_Add(, qwerd.word, qwerd.form, qwerd.qwerd, qwerd.keyer, qwerd.usage, qwerd.hint, qwerd.dictionary)
			} else {
				this.logEvent(3, foundKey " matched " foundKeys[foundKey] " times, not " requiredMatchCount)
			}
		}
	}

	AutoQwerdForm() {
		Gui EditorGUI:Default
		GuiControlGet form, , EditForm
		GuiControlGet word, , EditWord
		
		this.logEvent(3, "Generating auto qwerd for " form)
	 
		; Lowercase the whole word
		StringLower, qwerd, form

		; Vowels
		qwerd := RegexReplace(qwerd, "ea", "e")
		qwerd := RegexReplace(qwerd, "ao", "w")
		qwerd := RegexReplace(qwerd, "au", "w")
		qwerd := RegexReplace(qwerd, "eu", "u")

		; Consonant sets
		if (RegexMatch(word, "x")) {
			qwerd := RegexReplace(qwerd, "es", "x")
		}
		if (RegexMatch(word, "qu")) {
			qwerd := RegexReplace(qwerd, "k", "q")
		}

		; Prefixes
		qwerd := RegexReplace(qwerd, "pr(e|o)", "pr")
		qwerd := RegexReplace(qwerd, "per", "pr")
		
		qwerd := RegexReplace(qwerd, "-", "")
		
		GuiControl, Text, EditQwerd, %qwerd%

	}
				
	autoKey() {
		Gui EditorGUI:Default
		GuiControlGet word, , EditWord
		GuiControlGet qwerd, , EditQwerd
		GuiControlGet keyer, , EditKeyer
		GuiControlGet dict, , EditDict
		
		this.logEvent(3, "Mapping to dict " dict)
		dictionary := this.map.dictionaryShortToFullNames[dict]
		qwerdKey := dictionary "!!" word
		this.logEvent(3, "Seeking keyer for " qwerdKey)
		newKeyer := this.getNextKeyer(qwerdKey, qwerd, word)
		this.logEvent(2, "Setting newKeyer to " newKeyer)
		
		GuiControl, Text, EditKeyer, %newKeyer%
	}

	getNextKeyer(qwerdKey, qwerd, word) {
		this.logEvent(3, "Getting next keyer for " qwerd " and " qwerdKey)
		allMatchingKeys := {}
		allMatchingKeysCount := 0
		
		if (qwerd = "") {
			this.logEvent(4, "Empty lazy form. Returning nill")
			Return
		}
		
		; Loop across all forms and keep every form that begins with this lazy key
		for loopQwerdKey, garbage in this.map.qwerds {
			loopQwerd := this.map.qwerds.item(loopQwerdKey)
			if (RegExMatch(loopQwerd.qwerd,"^" qwerd ".?$")) {
				this.logEvent(4, loopQwerd.qwerd " begins with " qwerd)
				allMatchingKeys[loopQwerdKey] := loopQwerd
			}
		}
		this.logEvent(4, "Possible matching qwerds: " allMatchingKeys.MaxIndex() "(" allMatchingKeys.Length() ")")
			
		; Loop across all keyers in sequence, looking for the first that's not matched
		for index, keyer in this.keyers {
			keyedQwerd := qwerd . keyer
			this.logEvent(4, "Testing keyer '" keyer "' as " keyedQwerd)
			usedKeyFound := false
			for matchingKey, matchingQwerd in allMatchingKeys {
				if (not usedKeyFound) and (matchingQwerd.qwerd = keyedQwerd) {
					; This is a match, but it might be a self-match which would be the right one to return
					this.logEvent(4, "Getting dict fullname from " matchingQwerd.dict)
					matchedQwerdKey := this.map.dictionaryShortToFullNames[matchingQwerd.dict] "!!" matchingQwerd.word
					this.logEvent(4, "Matched " keyedQwerd " as " matchedQwerdKey)
					if (word = this.map.qwerds.item(qwerd).word) {
						this.logEvent(4, "Matched keyer, qwerd, and word " this.map.qwerds.item(qwerd).word ". Returning this keyer: " keyer)
						Return keyer
					} else {
						this.logEvent(4, "Keyer " this.map.qwerds.item(qwerd).word " taken. Owned by " matchingQwerd.word)
						usedKeyFound := true
						break
					}
				} else {
					this.logEvent(4, "Not a match for " matchingQwerd.qwerd)
				}
			}
			if not usedKeyFound {
				this.logEvent(4, "Returning available keyer " keyer)
				Return keyer
			}
		}
		this.logEvent(3, "No keyer found in available options") 
		Return "qq"
	}


	addValueToEditFields(WordAdd, FormAdd, QwerdAdd) {
		Gui EditorGUI:Default
		GuiControlGet word, , EditWord
		GuiControlGet form, , EditForm
		GuiControlGet qwerd, , EditQwerd
		GuiControlGet keyer, , EditKeyer
		
		; I'm not ready to build a full grammar here, but removing "e" is going to save time 
		if (InStr("er|ed|ing", WordAdd)) {
			; remove "e" from the end of the word when adding er, ed, or ing
			word := RegExReplace(word, "e$", "")
		}
		
		; When a keyer exists, we have to remove it from the lazy form
		if (StrLen(keyer)) {
			; remove keyer from the end of the lazy form before adding LazyAdd
			qwerd := RegExReplace(qwerd, keyer "$", "")
		}
		
		GuiControl, Text, EditWord, %word%%WordAdd%
		GuiControl, Text, EditForm, %form%%FormAdd%
		GuiControl, Text, EditQwerd, %qwerd%%QwerdAdd%
		GuiControl, Text, EditKeyer, 
		
	}
	LogEvent(verbosity, message) 
	{
		if (verbosity <= this.logVerbosity) 
		{
			event := new LoggingEvent("editor",A_Now,message,verbosity)
			this.logQueue.enqueue(event)
		}
	}
}


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