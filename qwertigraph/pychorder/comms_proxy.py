
from log_factory import get_logger
from PyQt6.QtCore import QObject, pyqtSignal


class Comms_Proxy(QObject):
    engineStarted = pyqtSignal()
    engineStopped = pyqtSignal()
    

    coachHintlogChanged = pyqtSignal(str)
    coachHintlogAppended = pyqtSignal(str)
    coachPredictionsChanged = pyqtSignal(str)
    coachPredictionsAppended = pyqtSignal(str)
    coachMissesChanged = pyqtSignal(str)
    coachMissesAppended = pyqtSignal(str)
    coachOpportunitiesChanged = pyqtSignal(str)
    coachOpportunitiesAppended = pyqtSignal(str)

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

        self.coachHintlogChanged.connect(self.ui.set_coach_hintlog)
        self.coachHintlogAppended.connect(self.ui.append_coach_hintlog)
        self.coachPredictionsChanged.connect(self.ui.set_coach_predictions)
        self.coachPredictionsAppended.connect(self.ui.append_coach_predictions)
        self.coachMissesChanged.connect(self.ui.set_coach_misses)
        self.coachMissesAppended.connect(self.ui.append_coach_misses)
        self.coachOpportunitiesChanged.connect(self.ui.set_coach_opportunities)
        self.coachOpportunitiesAppended.connect(self.ui.append_coach_opportunities)

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

    def signal_coach_set_hintlog(self, text: str):
        self._log.debug(f"Signaling Coach hintlog with new text {text}")
        self.coachHintlogChanged.emit(text)

    def signal_coach_append_hintlog(self, line: str):
        self._log.debug(f"Signaling Coach with append to hintlog with {line}")
        self.coachHintlogAppended.emit(line)

    def signal_coach_set_predictions(self, text: str):
        self._log.debug(f"Signaling Coach predictions with new text {text}")
        self.coachPredictionsChanged.emit(text)

    def signal_coach_append_predictions(self, line: str):
        self._log.debug(f"Signaling Coach with append to predictions with {line}")
        self.coachPredictionsAppended.emit(line)
   
    def signal_coach_set_misses(self, text: str):
        self._log.debug(f"Signaling Coach misses with new text {text}")
        self.coachMissesChanged.emit(text)

    def signal_coach_append_misses(self, line: str):
        self._log.debug(f"Signaling Coach with append to misses with {line}")
        self.coachMissesAppended.emit(line)

    def signal_coach_set_opportunities(self, text: str):
        self._log.debug(f"Signaling Coach opportunities with new text {text}")
        self.coachOpportunitiesChanged.emit(text)

    def signal_coach_append_opportunities(self, line: str):
        self._log.debug(f"Signaling Coach with append to opportunities with {line}")
        self.coachOpportunitiesAppended.emit(line)

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
