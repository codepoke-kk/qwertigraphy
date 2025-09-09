import os
from pynput import keyboard
from log_factory import get_logger

class Key_Input:
    _log = get_logger('KEYIN') 
    def __init__(self, key_queue):
        self.key_queue = key_queue
        self._log.info('Initiated Key Input')

    def on_press(self, key):
        self._log.debug(f"Pressed {key}")
        self.key_queue.push_keystroke(key)

    def start_listener(self):
        listener = keyboard.Listener(on_press=self.on_press)
        listener.start()          # runs in its own thread
        self._log.debug(f"Listener started as {listener}")
        return listener
