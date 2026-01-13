import keyboard
import mouse
import threading
from log_factory import get_logger
from collections import deque
from chorder_split_application import Chorder
from engine_signal_proxy import EngineSignalProxy

class Key_Input:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue, engine_signals: 'EngineSignalProxy'):
        self.engine_signals = engine_signals
        self.key_queue = key_queue
        self.emitable_end_keys = deque()
        self.next_end_key = ''
        self.blockable_normal_keys = deque()
        self.next_normal_key = ''
        self.failsafe = 0

        self.hook = None
        mouse.on_click(lambda: self.key_queue.clear_queue("Mouse left clicked"))
        mouse.on_right_click(lambda: self.key_queue.clear_queue("Mouse right clicked"))
                
        self._chorder = Chorder(self.engine_signals)
        self.CHORD_MAP = {
            "t+1": {"keys": 2, "backspaces": 1, "function": "output_time"},
            "d+1": {"keys": 2, "backspaces": 1, "function": "output_date"},
            "b+1": {"keys": 2, "backspaces": 1, "function": "output_password_a"},
            "b+2": {"keys": 2, "backspaces": 1, "function": "output_username_password_a"},
            "b+3": {"keys": 2, "backspaces": 1, "function": "output_username_a"},
            "b+4": {"keys": 2, "backspaces": 1, "function": "output_password_b"},
            "b+5": {"keys": 2, "backspaces": 1, "function": "output_username_password_b"},
            "b+6": {"keys": 2, "backspaces": 1, "function": "output_username_b"},
            "b+7": {"keys": 2, "backspaces": 1, "function": "output_password_c"},
            "b+8": {"keys": 2, "backspaces": 1, "function": "output_username_password_c"},
            "b+9": {"keys": 2, "backspaces": 1, "function": "output_username_c"}
        }
        self.registered_chords = []
        for combo, token in self.CHORD_MAP.items():
            cb = lambda t=token: self.chord_handler(t)
            hk = keyboard.add_hotkey(combo, cb, suppress=True)
            self.registered_chords.append(hk)
            self._log.debug(f"Registered hotkey: '{combo}' → {token}")

        self._log.info('Initiated Key Input')

    def chord_handler(self, token: str):
        self._log.info(f"Chord detected → {token}")
        for _ in range(token['backspaces']):
            keyboard.send("backspace") # Remove all keypresses from the focused application 
        self.key_queue.clear_queue("Chord detected")
        keyboard.unhook(self.hook) # Temporarily unhook to avoid recursion
        self._chorder.handle_token(token)
        self.hook = keyboard.hook(self.on_key, suppress=True)
        self._log.debug("Chord handled")

    def on_key(self, e):
        # global buffer

        if e.event_type == 'down':
            any_mod = keyboard.is_pressed('ctrl') or keyboard.is_pressed('alt') or keyboard.is_pressed('windows') or keyboard.is_pressed('cmd')
            self._log.debug(f"any_mod = {any_mod}")
            if any_mod:
                self._log.debug(f"Modifier key detected ({e.modifiers}), clearing queue")
                self.key_queue.clear_queue(f"modifier key with {e.name}")
                if keyboard.is_pressed('ctrl') and e.name in ['space', ',', '.', 'enter']:
                    self._log.debug(f"Ctrl-d {e.name} detected, sending through")
                    keyboard.release('ctrl')
                    keyboard.send(e.name)
                    if keyboard.is_pressed('ctrl'):
                        # If I do this wrong, ctrl stays stuck down
                        keyboard.press('ctrl')
                    if not keyboard.is_pressed('ctrl'):
                        # If the user released the ctrl key, make sure it's up
                        keyboard.release('ctrl')
                # If I don't return true here, ctrl-v leaves "v" in the queue and later expands 
                return True
            self._log.debug(f"Received key event: {e.name}")
            self.key_queue.push_keystroke(e.name)
            self._log.debug(f"Returning from on_key")
        return True

    def start_listening(self) -> None:
        self.hook = keyboard.hook(self.on_key, suppress=True)
        self._log.info("Started keyboard listener")
        # Notify the owner (the ListenerThread) the hook is active
        self.engine_signals.emit_started()

    def stop_listening(self) -> None:
        """Remove the keyboard hook and announce the stop."""
        if self.hook is not None:
            keyboard.unhook(self.hook)
            self.hook = None
            self._log.info("Unhooked keyboard listener")
        else:
            self._log.warning("stop_listening called but no hook was active")
        # Notify the owner (the ListenerThread) the unhook succeeded
        self.engine_signals.emit_stopped()
        
    def credentials_updated(self, new_credentials: dict):
        # self._log.info(f"Received updated credentials: {new_credentials}")
        self._chorder._vaulter.update_credentials(new_credentials)