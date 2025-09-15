
from pynput import keyboard 
from pynput.keyboard import Controller, Key
from log_factory import get_logger

class Key_Output:
    _log = get_logger('KEYOUT') 
    def __init__(self, scribe):
        self.controller = Controller()
        self.scribe = scribe
        self._log.info('Initiated Key Output')

    def replace_qwerd(self, qwerd, expansion, end_key):
        self._log.debug(f"Replacing {qwerd} with {expansion} ending with {end_key}")
        # Erase the qwerd characters from the active application 
        for _ in range(len(qwerd) + 1):
            self.controller.press(Key.backspace)
            self.controller.release(Key.backspace)

        # Type the expansion into the active application 
        for char in expansion:
            self.controller.type(char)

        # Type the end char
        if isinstance(end_key, keyboard.KeyCode):
            self.controller.type(end_key.char)
        else:
            self.controller.press(end_key)
            self.controller.release(end_key)

        self._log.debug(f"Recording note {qwerd}")
        self.scribe.record_note(qwerd, expansion, end_key)
