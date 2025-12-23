
from log_factory import get_logger
from PyQt6.QtCore import QObject, pyqtSignal


class Comms_Proxy(QObject):
    coachUpperChanged = pyqtSignal(str)
    coachLowerChanged = pyqtSignal(str)
    coachUpperAppended = pyqtSignal(str)
    coachLowerAppended = pyqtSignal(str)
    performanceUpdated = pyqtSignal(str)

    def __init__(self, ui: QObject, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._log = get_logger('COMMS')
        self.ui = ui
        self.engine = None
        self.key_input = None

        self.coachUpperChanged.connect(self.ui.set_coach_upper)
        self.coachLowerChanged.connect(self.ui.set_coach_lower)
        self.coachUpperAppended.connect(self.ui.append_coach_upper)
        self.coachLowerAppended.connect(self.ui.append_coach_lower)
        self.performanceUpdated.connect(self.ui.update_performance)

    def set_engine(self, engine):
        self._log.debug("Setting engine to {engine}")
        self.engine(engine)

    def set_key_input(self, key_input):
        self._log.debug("Setting key_input to {key_input}")
        self.key_input = key_input

    # expose only the subset each part is allowed to fire
    def signal_ui_engine_started(self):
        self._log.debug("Call to signal_ui_engine_started")
        '''
        if callable(self.notify_engine_started):
            self._log.info("Calling listener engine started notification")
            self.notify_engine_started()
        else:
            self._log.warning("No notify_engine_started callback set")
        '''

    def signal_ui_engine_stopped(self):
        self._log.debug("Call to signal_ui_engine_stopped")
        '''
        if callable(self.notify_engine_stopped):
            self._log.info("Calling listener engine stopped notification")
            self.notify_engine_stopped()
        else:
            self._log.warning("No notify_engine_stopped callback set")
        '''


    def signal_ui_get_credential_dict(self) -> dict:
        self._log.debug("Call to signal_ui_get_credential_dict")
        '''
        if callable(self.get_credential_dict):
            self._log.debug("Calling listener get credential dictionary")
            return self.get_credential_dict()
        else:
            self._log.warning("No get_credential_dict callback set")
        '''

    def signal_performance_updated(self, line: str):
        self._log.debug("Call to signal_performance_updated")
        self.performanceUpdated.emit(line)
        
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

    def signal_vaulter_new_credentials(self, credentials):
        self._log.debug(f"Signaling Vaulter with new credentials")
        self.key_input.credentials_updated(credentials)
