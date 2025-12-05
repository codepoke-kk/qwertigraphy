import logging
from PyQt6.QtCore import QThread, pyqtSignal, QObject, pyqtSlot, QEventLoop, Qt
import uuid
from log_factory import get_logger   # keep your existing logger factory

# -----------------------------------------------------------------
# 1️⃣  A tiny QObject that emits signals from the listener
# -----------------------------------------------------------------
class ListenerSignals(QObject):
    # Emitted by the UI to request actions from the listener.
    start_requested = pyqtSignal() 
    stop_requested = pyqtSignal() 
    updated_credentials = pyqtSignal(dict) 
    # Emitted by the listener to notify the UI of various events.
    engine_started = pyqtSignal()
    engine_stopped = pyqtSignal()
    performance_updated = pyqtSignal(str)  


# -----------------------------------------------------------------
# 2️⃣  QThread subclass that runs your existing Key_Input class
# -----------------------------------------------------------------
class ListenerThread(QThread):
    """
    Runs the whole `Key_Input` stack in a separate thread.
    The thread lives as long as `run()` does; when `quit()` is called,
    we ask the listener to shut down gracefully.
    """
    
    _log: logging.Logger = get_logger("THREAD")

    def __init__(self, parent=None):
        super().__init__(parent)
        self.signals = ListenerSignals()
        self._key_queue = None 
        self._stop_requested = False

        # Connect the UI‑to‑listener requests to a slot that runs in this thread
        self.signals.start_requested.connect(self._handle_start_request)
        self.signals.stop_requested.connect(self._handle_stop_request)
        self.signals.updated_credentials.connect(self._handle_updated_credentials)

        # Keep a reference to the objects we need to build the listener.
        # They will be created **inside** the thread (in run()).
        self._key_input = None

        # Logger – we reuse the same global logger you already have.
        self._log.info("Initialized ListenerThread")

    # -----------------------------------------------------------------
    # The heavy lifting – this runs in the *worker* thread.
    # -----------------------------------------------------------------
    def run(self) -> None:
        """
        Build the whole listener chain and block on `keyboard.wait('esc')`.
        When the user hits ESC (or we set `_stop_requested`), we clean up.
        """
        self._log.info("Listener thread to run")

        from engine_signal_proxy import EngineSignalProxy
        from key_input import Key_Input        
        from key_output import Key_Output
        from engine import Expansion_Engine
        from scribe import Scribe
        from key_queue import Key_Queue

        # Construct the objects exactly as you did before.
        engine_signals = EngineSignalProxy()
        scribe = Scribe()
        key_output = Key_Output(scribe)
        engine = Expansion_Engine(key_output, engine_signals)
        self._engine = engine
        key_queue = Key_Queue(engine)   

        # Notifications from Engine to UI
        engine_signals.notify_engine_started = lambda: self.signals.engine_started.emit()
        engine_signals.notify_engine_stopped  = lambda: self.signals.engine_stopped.emit()
        engine_signals.notify_performance_updated  = lambda data: self.signals.performance_updated.emit(data)
        self._log.info("Listener thread setup complete")
        # -----------------------------------------------------------------
        # Finally start the Key_Input listener
        # -----------------------------------------------------------------
        self._key_input = Key_Input(key_queue, engine_signals)

        self._key_input.start_listening()

        # When the listener returns 
        self._log.info("Listener thread finished: cleaning up")

    # Messages from the UI to start/stop the engine
    @pyqtSlot()
    def _handle_start_request(self):
        self._log.info("Listener received start request from Main Window - rebuilding dictionaries and hints")
        self._engine.dictionaries = self._engine.get_dictionaries(self._engine.dictionary_paths)
        self._engine.expansions = self._engine.get_expansions(self._engine.dictionaries)
        self._engine.hints = self._engine.build_hints(self._engine.expansions)
        self._engine.reverse_hints = self._engine.build_reverse_hints(self._engine.expansions)
        self._log.info("Listener rebuilt dictionaries - starting engine")
        self._key_input.start_listening()

    @pyqtSlot()
    def _handle_stop_request(self):
        self._log.info("Listener received stop request from Main Window – shutting down engine")
        self._key_input.stop_listening()

    @pyqtSlot(dict)
    def _handle_updated_credentials(self, new_credentials: dict):
        self._log.info("Listener received updated credentials from Main Window – updating engine")
        # new_credentials = {'username_a': "hello",'password_a': "world"}  # Replace with actual fetching logic
        self._key_input.credentials_updated(new_credentials)


    # -----------------------------------------------------------------
    # Public method to request a graceful shutdown from the UI thread.
    # Called on shutdown 
    # -----------------------------------------------------------------
    def request_stop(self):
        """
        Called from the main (GUI) thread when you want the listener to exit.
        It sets a flag and sends a fake ESC key press to unblock `keyboard.wait`.
        """
        self._log.info("Shutdown requested from UI")
        self._stop_requested = True

        # The `keyboard` library reacts to a synthetic key press.
        # This will break the blocking `keyboard.wait('esc')` call.
        try:
            import keyboard
            keyboard.send('esc')
        except Exception as exc:   # defensive – keyboard may already be unavailable
            self._log.warning(f"Failed to synthesize ESC for shutdown: {exc}")

        # After the synthetic ESC, the `run()` method will exit and the thread
        # will finish automatically.
