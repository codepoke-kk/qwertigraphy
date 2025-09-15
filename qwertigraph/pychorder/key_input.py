import threading
from pynput import keyboard
from log_factory import get_logger


class Key_Input:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self.controller = keyboard.Controller()
        # Guard that tells us whether we are currently injecting a key ourselves
        self._injecting = False
        self._log.debug(f"Flag starting as {self._injecting}")
        self._log.info('Initiated Key Input')
        self.failsafe = 0

    def on_press(self, key):
        # If we are *injecting* a key, skip everything – this prevents recursion
        self._log.debug(f"Injecting {key}")
        self._log.debug(f"Flag is {self._injecting}")
        if self._injecting:
            self._log.debug(f"Ignoring synthetic key {key}")
            return True

        self._log.debug(f"Pressed {key}")

        self.key_queue.push_keystroke(key)
        self._forward_normal_key(key)

        return True

    def _forward_normal_key(self, key):
        """Send the key to the foreground window without triggering recursion."""
        # Mark that we are about to inject a synthetic event
        self._injecting = True
        # self._log.debug(f"Set flag to true")
        try:
            self.controller.press(key)
            self.controller.release(key)
        finally:
            # Reset the flag so the next real key is processed normally
            # self._log.debug(f"Unset flag")
            self._injecting = False
        # self._log.debug(f"Flag is {self._injecting}")

    def start_listener(self):
        listener = keyboard.Listener(
            on_press=self.on_press,
            suppress=True          # block the original hardware event
        )
        listener.start()          # runs in its own thread
        self._log.debug(f"Listener started as {listener}")
        return listener