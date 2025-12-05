import time, sys
from typing import List, Tuple, Iterable
from collections import namedtuple
from log_factory import get_logger
from PyQt6.QtWidgets import QApplication
from coach_viewport import Coach_Viewport
import multiprocessing

# Using __slots__ eliminates the per‑instance __dict__ 
Note = namedtuple("Note", ("key", "word", "timestamp", "end_key", "end_key_str"))
Note.__slots__ = () 
# ----------------------------------------------------------------------
# Helper that launches the UI process (coach)
# ----------------------------------------------------------------------
def _run_coach_process():
    """Entry point executed inside the child process."""
    from coach_viewport import start_coach_process
    start_coach_process()          # blocks forever (Qt event loop)

def launch_coach():
    """
    Starts the coach process using the 'spawn' start method (required on Windows).
    Returns the Process object so we can terminate it later.
    """
    ctx = multiprocessing.get_context('spawn')
    proc = ctx.Process(target=_run_coach_process,
                       daemon=True,
                       name='CoachProcess')
    proc.start()
    return proc

class Scribe:
    _log = get_logger('SCRIBE')
    _tape_log = get_logger('TAPE')
    _coach_proxy = None
    _coach_process = None
        
    _END_KEY_SYMBOLS = {
        "space": "␣",   # space → middle dot
        " ": "␣",   # space → middle dot
        "enter": "↵",  # newline (Enter) → pilcrow
        "\n": "↵",  # newline (Enter) → pilcrow
        "\r": "↵",  # carriage‑return (also Enter on Windows) → pilcrow
        "tab": "⇥",  # tab → right‑pointing triangle (feel free to change)
        "\t": "⇥",  # tab → right‑pointing triangle (feel free to change)
    }

    def __init__(self) -> None:
        self._tape: List[Note] = []
        self._log.info('Initiated Scribe')
        self._start_coach()
        # Small pause to let the manager finish its handshake
        time.sleep(0.5)


    def _start_coach(self):
        """Spawn the UI process and obtain a proxy to the Coach dispatcher."""
        self._coach_process = launch_coach()

        # --------------------------------------------------------------
        # Connect to the same address/authkey we used in coach_ui.start_coach_process
        # --------------------------------------------------------------
        from multiprocessing.managers import BaseManager

        class CoachClient(BaseManager):
            pass

        CoachClient.register('Coach')
        self._coach_proxy = CoachClient(address=('localhost', 6000),
                                        authkey=b'coach-secret')
        self._coach_proxy.connect()
        self._coach = self._coach_proxy.Coach()   # <-- proxy to the dispatcher

        # --------------------------------------------------------------
        # Initial UI configuration (calls travel across processes)
        # --------------------------------------------------------------
        self._coach.set_upper_text("Shorthand Tape")
        self._coach.set_lower_text("Hints")

    # ------------------------------------------------------------------
    # Convenience wrappers that forward to the UI (same signatures as before)
    # ------------------------------------------------------------------
    def set_upper_text(self, txt: str):
        self._coach.set_upper_text(txt)

    def set_lower_text(self, txt: str):
        self._coach.set_lower_text(txt)

    def append_to_upper(self, line: str):
        self._coach.append_to_upper(line)

    def append_to_lower(self, line: str):
        # print(f"Appending to lower via Scribe: {line}")
        self._coach.append_to_lower(line)


    def record_note(self, key, word, end_key):
        if hasattr(end_key, 'value'):
            self._log.debug(f"Getting string value of special end key {end_key}")
            end_key_str = f"{end_key.value}"
        elif hasattr(end_key, 'char'):
            self._log.debug(f"Getting string value of legacy end key {end_key}")
            end_key_str = f"{end_key.char}"
        else:
            # Regular character key
            self._log.debug(f"Getting string value of normal end key {end_key}")
            end_key_str = self._END_KEY_SYMBOLS.get(end_key, f"{end_key}")
        self._log.debug(f"Recording input {key} to {word} ending with {end_key_str}")
        self._tape_log.info(f"{key:<6}{word:<30}{end_key_str:>6}")
        self.append_to_upper(f"{key:<7} {word}{end_key_str}")
        ts = time.perf_counter()
        self._tape.append(Note(key, word, ts, end_key, end_key_str))

    def readback_notes(self) -> List[Note]:
        """Return a shallow copy that can be iterated without mutating the stack."""
        return list(self._tape)
    
    # ------------------------------------------------------------------
    # Clean‑up
    # ------------------------------------------------------------------
    def shutdown(self):
        if self._coach_process and self._coach_process.is_alive():
            # Ask the UI to close gracefully (optional)
            # self._coach.close_viewport()   # you could expose such a slot
            self._coach_process.terminate()
            self._coach_process.join()
        