import keyboard
import mouse
import threading
from log_factory import get_logger
from collections import deque
from chorder import Chorder

class Key_Input:
    _log = get_logger('KEYIN')
    _chorder = Chorder()

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self.emitable_end_keys = deque()
        self.next_end_key = ''
        self.blockable_normal_keys = deque()
        self.next_normal_key = ''
        self._log.info('Initiated Key Input')
        self.failsafe = 0

        self.hook = keyboard.hook(self.on_key, suppress=True)
        mouse.on_click(lambda: self.key_queue.clear_queue("Mouse left clicked"))
        mouse.on_right_click(lambda: self.key_queue.clear_queue("Mouse right clicked"))
                
        self.CHORD_MAP = {
            "b+1": {"keys": 2, "backspaces": 1, "function": "output_base_password"},
            "b+2": {"keys": 2, "backspaces": 1, "function": "output_base_username_password"},
            "b+3": {"keys": 2, "backspaces": 1, "function": "new_base_password"}
        }
        self.registered_chords = []
        for combo, token in self.CHORD_MAP.items():
            cb = lambda t=token: self.chord_handler(t)
            hk = keyboard.add_hotkey(combo, cb, suppress=True)
            self.registered_chords.append(hk)
            self._log.debug(f"Registered hotkey: '{combo}' → {token}")

        self.start_listening

    def chord_handler(self, token: str):
        self._log.info(f"Chord detected → {token}")
        for _ in range(token['backspaces']):
            keyboard.send("backspace") # Remove all keypresses from the focused application 
        keyboard.unhook(self.hook) # Temporarily unhook to avoid recursion
        print("Temporarily unhooked keyboard to handle chord")
        self.key_queue.clear_queue("Chord detected")
        self._chorder.handle_token(token)
        # self.hook = keyboard.hook(self.on_key, suppress=True)

    def on_key(self, e):
        # global buffer

        if e.event_type == 'down':
            any_mod = keyboard.is_pressed('ctrl') or keyboard.is_pressed('alt') or keyboard.is_pressed('windows') or keyboard.is_pressed('cmd')
            self._log.debug(f"any_mod = {any_mod}")
            if any_mod:
                self._log.debug(f"Modifier key detected ({e.modifiers}), clearing queue")
                self.key_queue.clear_queue(f"modifier key with {e.name}")
                return True
            self._log.debug(f"Received key event: {e.name}")
            self.key_queue.push_keystroke(e.name)
            self._log.debug(f"Returning from on_key")
        return True

    def start_listening(self):
        self.hook = keyboard.hook(self.on_key, suppress=True)
        self._log.info("Started keyboard listener")

    def stop_listening(self):
        keyboard.unhook(self.hook)
        self._log.info("Unhooked keyboard listener")    