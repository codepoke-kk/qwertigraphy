
from log_factory import get_logger
from collections.abc import Callable

class EngineSignalProxy:
    def __init__(self):
        self._log = get_logger('SIGNAL')
        self.notify_engine_started: Callable[[], None] | None = None
        self.notify_engine_stopped:  Callable[[], None] | None = None
        self.notify_performance_updated:  Callable[[str], None] | None = None
        self.get_credential_dict:  Callable[[], dict] | None = None

    # expose only the subset each part is allowed to fire
    def emit_started(self):
        if callable(self.notify_engine_started):
            self._log.info("Calling listener engine started notification")
            self.notify_engine_started()
        else:
            self._log.warning("No notify_engine_started callback set")

    def emit_stopped(self):
        if callable(self.notify_engine_stopped):
            self._log.info("Calling listener engine stopped notification")
            self.notify_engine_stopped()
        else:
            self._log.warning("No notify_engine_stopped callback set")

    def emit_performance_updated(self, data: str):
        if callable(self.notify_performance_updated):
            self._log.debug("Calling listener performance updated notification with {data}")
            self.notify_performance_updated(data)
        else:
            self._log.warning("No notify_performance_updated callback set")

    def set_callback(self, cb: Callable[[], dict]) -> None:
        self._log.debug("Callback registered")
        self.get_credential_dict = cb

    def emit_get_credential_dict(self) -> dict:
        self._log.debug("Call to emit_get_credential_dict")
        if callable(self.get_credential_dict):
            self._log.debug("Calling listener get credential dictionary")
            return self.get_credential_dict()
        else:
            self._log.warning("No get_credential_dict callback set")
