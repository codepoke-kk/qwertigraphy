import time
from typing import List, Tuple, Iterable
from collections import namedtuple
from log_factory import get_logger
from pynput import keyboard 

# Using __slots__ eliminates the per‑instance __dict__ 
Note = namedtuple("Note", ("key", "word", "timestamp", "end_key", "end_key_str"))
Note.__slots__ = () 

class Scribe:
    _log = get_logger('SCR')
    _tape_log = get_logger('TAPE')
    __slots__ = ("_tape",)

    def __init__(self) -> None:
        self._tape: List[Note] = []
        self._log.info('Initiated Scribe')

    def record_note(self, key, word, end_key):
        if hasattr(end_key, 'value'):
            self._log.debug(f"Getting string value of special end key {end_key}")
            end_key_str = f"{end_key.value!r}"
        elif hasattr(end_key, 'char'):
            self._log.debug(f"Getting string value of legacy end key {end_key}")
            end_key_str = f"{end_key.char!r}"
        else:
            # Regular character key
            self._log.debug(f"Getting string value of normal end key {end_key}")
            end_key_str = f"{end_key!r}"
        self._log.debug(f"Recording input {key} to {word} ending with {end_key_str}")
        self._tape_log.info(f"{key:<6}{word:<30}{end_key_str:>6}")
        ts = time.perf_counter()
        self._tape.append(Note(key, word, ts, end_key, end_key_str))

    def readback_notes(self) -> List[Note]:
        """Return a shallow copy that can be iterated without mutating the stack."""
        return list(self._tape)