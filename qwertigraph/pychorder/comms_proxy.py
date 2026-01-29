
from log_factory import get_logger
from PyQt6.QtCore import QObject, pyqtSignal


class Comms_Proxy(QObject):
    engineStarted = pyqtSignal()
    engineStopped = pyqtSignal()
    coachUpperChanged = pyqtSignal(str)
    coachLowerChanged = pyqtSignal(str)
    coachUpperAppended = pyqtSignal(str)
    coachLowerAppended = pyqtSignal(str)
    performanceUpdated = pyqtSignal(str)
    greggDictLookupWord = pyqtSignal()
    focusCoach = pyqtSignal()
    focusTab = pyqtSignal(str, str)

    def __init__(self, ui: QObject, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._log = get_logger('COMMS')
        self.ui = ui
        self.engine = None
        self.key_input = None

        self.engineStarted.connect(self.ui.on_engine_started)
        self.engineStopped.connect(self.ui.on_engine_stopped)
        self.performanceUpdated.connect(self.ui.update_performance)
        self.greggDictLookupWord.connect(self.ui.gregg_dict_lookup_word)
        self.focusTab.connect(self.ui.focus_tab)
        self.focusCoach.connect(self.ui.focus_coach)
        self.coachUpperChanged.connect(self.ui.set_coach_upper)
        self.coachLowerChanged.connect(self.ui.set_coach_lower)
        self.coachUpperAppended.connect(self.ui.append_coach_upper)
        self.coachLowerAppended.connect(self.ui.append_coach_lower)

    # Set necessary objects 
    def set_engine(self, engine):
        self._log.debug("Setting engine to {engine}")
        self.engine(engine)

    def set_key_input(self, key_input):
        self._log.debug("Setting key_input to {key_input}")
        self.key_input = key_input

    # Signals to UI from Engine 
    def signal_performance_updated(self, line: str):
        self._log.debug("Call to signal_performance_updated")
        self.performanceUpdated.emit(line)
        
    def signal_gregg_dict_lookup_word(self):
        self._log.debug("Call to signal_gregg_dict_lookup_word")
        self.greggDictLookupWord.emit()
        
    def signal_focus_tab(self, tab_focus: list):
        self._log.debug(f"Call to signal_focus_tab with {tab_focus}")
        self.focusTab.emit(tab_focus[0], tab_focus[1])
        
    def signal_focus_coach(self):
        self._log.debug("Call to signal_focus_coach")
        self.focusCoach.emit()
        
    def signal_coach_set_upper(self, text: str):
        self._log.debug(f"Signaling Coach upper with new text {text}")
        self.coachUpperChanged.emit(text)

    def signal_coach_set_lower(self, text: str):
        self._log.debug(f"Signaling Coach lower with new text {text}")
        self.coachLowerChanged.emit(text)

    def signal_coach_append_upper(self, line: str):
        self._log.debug(f"Signaling Coach with append to upper with {line}")
        self.coachUpperAppended.emit(line)

    def signal_coach_append_lower(self, line: str):
        self._log.debug(f"Signaling Coach with append to lower with {line}")
        self.coachLowerAppended.emit(line)

    def signal_ui_engine_started(self):
        self._log.debug(f"Signaling UI the engine has started")
        self.engineStarted.emit()

    def signal_ui_engine_stopped(self):
        self._log.debug(f"Signaling UI the engine has stopped")
        self.engineStopped.emit()

    # Signals to Engine from the UI 
    def signal_engine_start(self):
        self._log.debug(f"Signaling Engine to start")
        self.key_input.start_listening()

    def signal_engine_stop(self):
        self._log.debug(f"Signaling Engine to stop")
        self.key_input.stop_listening()

    def signal_vaulter_new_credentials(self, credentials):
        self._log.debug(f"Signaling Vaulter with new credentials")
        self.key_input.credentials_updated(credentials)
