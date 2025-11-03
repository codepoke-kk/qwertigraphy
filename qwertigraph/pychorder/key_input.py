import keyboard
import threading
from log_factory import get_logger
from collections import deque

class Key_Input:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self.emitable_end_keys = deque()
        self.next_end_key = ''
        self.blockable_normal_keys = deque()
        self.next_normal_key = ''
        self._log.info('Initiated Key Input')
        self.failsafe = 0

        self.hook = keyboard.hook(self.on_key, suppress=True)
                
        try:
            keyboard.wait('esc') # Wait for the 'esc' key to exit the script
        finally:
            keyboard.unhook(self.hook) # Remove the hook when the script is done

    def on_key(self, e):
        global buffer

        if e.event_type == 'down':
            self._log.debug(f"Received key event: {e.name}")
            self.key_queue.push_keystroke(e.name)
            self._log.debug(f"Returning from on_key")
        return True

