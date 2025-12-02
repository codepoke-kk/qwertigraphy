import logging
from PyQt6.QtCore import QThread, pyqtSignal, QObject

# -----------------------------------------------------------------
# 1️⃣  A tiny QObject that emits signals from the listener
# -----------------------------------------------------------------
class ListenerSignals(QObject):
    """
    Signals that the background listener can emit.
    Extend with more signals as you need (e.g. speed updates, error reports).
    """
    speed_changed = pyqtSignal(int)          # example: emit new speed value
    engine_started = pyqtSignal()
    engine_stopped = pyqtSignal()
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
    def __init__(self, key_queue, parent=None):
        super().__init__(parent)
        self.signals = ListenerSignals()
        self._key_queue = key_queue
        self._stop_requested = False

        # Keep a reference to the objects we need to build the listener.
        # They will be created **inside** the thread (in run()).
        self._key_input = None

        # Logger – we reuse the same global logger you already have.
        self._log = logging.getLogger("QW.ListenerThread")

    # -----------------------------------------------------------------
    # The heavy lifting – this runs in the *worker* thread.
    # -----------------------------------------------------------------
    def run(self) -> None:
        """
        Build the whole listener chain and block on `keyboard.wait('esc')`.
        When the user hits ESC (or we set `_stop_requested`), we clean up.
        """
        self._log.info("Listener thread started")

        # -----------------------------------------------------------------
        # Build the same pipeline you had in the UI code, but **inside** the thread.
        # -----------------------------------------------------------------
        from key_input import Key_Input          # <-- your existing class
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

        # -----------------------------------------------------------------
        # Finally start the Key_Input listener (this blocks until ESC or stop)
        # -----------------------------------------------------------------
        self._key_input = Key_Input(key_queue)

        # When the listener returns (ESC pressed or we forced stop) we fall
        # through to the cleanup code below.
        self._log.info("Listener thread finished – cleaning up")
        # No explicit `unhook` needed – `Key_Input.__del__` already does it,
        # but you can call it manually if you added a custom shutdown method.

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