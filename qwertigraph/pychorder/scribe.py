import time, sys
from typing import List, Tuple, Iterable
from collections import namedtuple
from log_factory import get_logger
from comms_proxy import Comms_Proxy

# Using __slots__ eliminates the per‑instance __dict__ 
Note = namedtuple("Note", ("key", "word", "timestamp", "end_key", "end_key_str"))
Note.__slots__ = () 

class Scribe:
    _log = get_logger('SCRIBE')
    _tape_log = get_logger('TAPE')
        
    _END_KEY_SYMBOLS = {
        "space": "␣",   # space → middle dot
        " ": "␣",   # space → middle dot
        "enter": "↵",  # newline (Enter) → pilcrow
        "\n": "↵",  # newline (Enter) → pilcrow
        "\r": "↵",  # carriage‑return (also Enter on Windows) → pilcrow
        "tab": "⇥",  # tab → right‑pointing triangle (feel free to change)
        "\t": "⇥",  # tab → right‑pointing triangle (feel free to change)
    }

    def __init__(self, comms_proxy) -> None:
        self.comms_proxy = comms_proxy
        self._tape: List[Note] = []
        self._log.info('Scribe starting Coach')
        self._log.info('Initiated Scribe')


    # ------------------------------------------------------------------
    # Convenience wrappers that forward to the UI (same signatures as before)
    # ------------------------------------------------------------------
    def set_upper_text(self, text: str):
        self._log.debug(f"Setting upper text via Scribe: {text}")
        self.comms_proxy.signal_coach_set_upper(text)

    def set_lower_text(self, text: str):
        self._log.debug(f"Setting lower text via Scribe: {text}")
        self.comms_proxy.signal_coach_set_lower(text)

    def append_to_upper(self, line: str):
        self._log.debug(f"Appending to upper text via Scribe: {line}")
        self.comms_proxy.signal_coach_append_upper(line)

    def append_to_lower(self, line: str):
        self._log.debug(f"Appending to lower text via Scribe: {line}")
        self.comms_proxy.signal_coach_append_lower(line)


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
        