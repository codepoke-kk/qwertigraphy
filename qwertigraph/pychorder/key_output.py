
import keyboard 
from log_factory import get_logger

class Key_Output:
    _log = get_logger('KEYOUT') 
    def __init__(self, scribe):
        self.scribe = scribe
        self._log.info('Initiated Key Output')

    def replace_qwerd(self, qwerd, expansion, end_key):
        self._log.debug(f"Replacing {qwerd} with {expansion} ending with {end_key}")
        # Erase the qwerd characters from the active application 
        for _ in range(len(qwerd)):
            keyboard.send("backspace")

        # Type the expansion into the active application
        keyboard.write(expansion)

        self._log.debug(f"Recording note {qwerd}")
        self.scribe.record_note(qwerd, expansion, end_key)

    def log_no_action(self, qwerd, end_key):
        self._log.debug(f"No expansion for {qwerd}, ending with {end_key}")
        self.scribe.record_note(qwerd, qwerd, end_key) 
