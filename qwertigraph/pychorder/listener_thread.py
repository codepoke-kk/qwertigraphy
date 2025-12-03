import logging
from PyQt6.QtCore import QThread, pyqtSignal, QObject, pyqtSlot, QEventLoop
import uuid
from log_factory import get_logger   # keep your existing logger factory

# -----------------------------------------------------------------
# 1️⃣  A tiny QObject that emits signals from the listener
# -----------------------------------------------------------------
class ListenerSignals(QObject):
    # Emitted by the UI to request actions from the listener.
    start_requested = pyqtSignal() 
    stop_requested = pyqtSignal() 
    # Emitted by the listener to notify the UI of various events.
    speed_changed = pyqtSignal(int)          # example: emit new speed value
    engine_started = pyqtSignal()
    engine_stopped = pyqtSignal()
    needCredentials = pyqtSignal(str)          # request ID
    gotCredentials = pyqtSignal(dict)          # {"id": ..., "data": {...}}
    # You can also add a generic `debug(str)` signal if you want to forward
    # log messages to the UI.


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

    def __init__(self, key_queue, parent=None):
        super().__init__(parent)
        self.signals = ListenerSignals()
        self._key_queue = key_queue
        self._stop_requested = False

        # Connect the UI‑to‑listener request to a slot that runs in this thread
        self.signals.start_requested.connect(self._handle_start_request)
        self.signals.stop_requested.connect(self._handle_stop_request)

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

        from key_input import Key_Input        
        from key_output import Key_Output
        from engine import Expansion_Engine
        from scribe import Scribe
        from key_queue import Key_Queue

        # Construct the objects exactly as you did before.
        scribe = Scribe()
        key_output = Key_Output(scribe)
        engine = Expansion_Engine(key_output)
        key_queue = Key_Queue(engine)   # we ignore the `key_queue` passed in,
                                        # because we need a fresh one that lives in this thread.
        # IMPORTANT: we keep a reference to the *queue* so we can push messages
        # from the UI later (e.g. to change speed).  If you need that, expose it
        # via an attribute on the thread (self.key_queue = key_queue).

        # Store the queue for later UI access (optional)
        self.key_queue = key_queue

        # -----------------------------------------------------------------
        # Hook up a couple of example callbacks from the engine to Qt signals.
        # Adjust according to the real callbacks you have.
        # -----------------------------------------------------------------
        # Example: suppose your `Expansion_Engine` calls `engine.report_speed(val)`
        # whenever the speed changes.  You can monkey‑patch it here:
        def report_speed(val: int):
            self._log.debug(f"Engine reported speed = {val}")
            self.signals.speed_changed.emit(val)

        engine.report_speed = report_speed   # <-- replace with your real method name

        # Example: engine start/stop notifications
        engine.notify_start = lambda: self.signals.engine_started.emit()
        engine.notify_stop  = lambda: self.signals.engine_stopped.emit()

        self._log.info("Listener thread setup complete")
        # -----------------------------------------------------------------
        # Finally start the Key_Input listener (this blocks until ESC or stop)
        # -----------------------------------------------------------------
        self._key_input = Key_Input(key_queue)

        # When the listener returns (ESC pressed or we forced stop) we fall
        # through to the cleanup code below.
        self._log.info("Listener thread finished – cleaning up")
        # No explicit `unhook` needed – `Key_Input.__del__` already does it,
        # but you can call it manually if you added a custom shutdown method.

    @pyqtSlot()
    def _handle_start_request(self):
        self._log.info("Listener received start request from Main Window – starting engine")
        self._key_input.start_listening()
        # ---- INSERT YOUR ENGINE‑STOP LOGIC HERE ----
        # Example: self.engine_controller.stop()
        # -------------------------------------------

        # If you later want to inform the UI that the engine *has* stopped,
        # you can emit `self.engine_stopped.emit()` here.
        # For now we leave it silent as you requested.

    @pyqtSlot()
    def _handle_stop_request(self):
        self._log.info("Listener received stop request from Main Window – shutting down engine")
        self._key_input.stop_listening()
        # ---- INSERT YOUR ENGINE‑STOP LOGIC HERE ----
        # Example: self.engine_controller.stop()
        # -------------------------------------------

        # If you later want to inform the UI that the engine *has* stopped,
        # you can emit `self.engine_stopped.emit()` here.
        # For now we leave it silent as you requested.



    # ------------------------------------------------------------------
    # Helper that asks the GUI for the current values and blocks until they arrive
    # ------------------------------------------------------------------
    def _fetch_credentials(self) -> dict:
        request_id = str(uuid.uuid4())
        # Connect a temporary slot that will capture the response for this ID
        loop = QEventLoop()                     # local event loop to block

        @pyqtSlot(dict)
        def _on_reply(payload: dict):
            if payload.get("id") == request_id:
                self._latest_creds = payload["data"]
                loop.quit()                     # stop waiting

        self.gotCredentials.connect(_on_reply)
        self.needCredentials.emit(request_id)   # ask the GUI
        loop.exec()                             # wait until reply arrives
        self.gotCredentials.disconnect(_on_reply)
        return self._latest_creds
    
    # -----------------------------------------------------------------
    # Public method to request a graceful shutdown from the UI thread.
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
