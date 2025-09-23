from pynput import keyboard
from log_factory import get_logger
from collections import deque



class Key_Input:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self.controller = keyboard.Controller()
        self.through_keys = deque()
        self.next_through_key = ''
        self._log.info('Initiated Key Input')
        self.failsafe = 0

    def on_press(self, key):
        self.failsafe += 1
        if self.failsafe > 30:
           exit(1)
        # If we are *injecting* a key, skip everything – this prevents recursion
        if not self.next_through_key and self.through_keys:
            self.next_through_key = self.through_keys.popleft()
            self._log.debug(f"Loaded up next through key with {self.next_through_key}")
        else:
            self._log.debug(f"No through keys queued")

        self._log.debug(f"Injecting {key} if it is not '{self.next_through_key}'")
        if not self.next_through_key or key != self.next_through_key:
            self._log.debug(f"Pressed {key}")
            self.key_queue.push_keystroke(key)
            self._forward_normal_key(key)
        elif key in self.key_queue.end_keys:
            self._log.debug(f"Found key in end_keys")
            self.key_queue.push_keystroke(key)
        else:
            self._log.debug(f"{self.next_through_key} ignored as synthetic")
            self.next_through_key = ''

        return True

    def _forward_normal_key(self, key):
        """Send the key to the foreground window without triggering recursion."""
        # Mark that we are about to inject a synthetic event
        self._log.debug(f"Forwarding {key}")
        self.through_keys.append(key)
        self._log.debug(f"Through keys are now {self.through_keys}")
        self.controller.press(key)
        self.controller.release(key)

    def start_listener(self):
        listener = keyboard.Listener(
            on_press=self.on_press,
            suppress=True          # block the original hardware event
        )
        listener.start()          # runs in its own thread
        self._log.debug(f"Listener started as {listener}")
        return listener