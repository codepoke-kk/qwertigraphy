from pynput import keyboard
from log_factory import get_logger
from collections import deque



class Key_Input:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self.controller = keyboard.Controller()
        self.emitable_end_keys = deque()
        self.next_end_key = ''
        self.blockable_normal_keys = deque()
        self.next_normal_key = ''
        self._log.info('Initiated Key Input')
        self.failsafe = 0

    def on_press(self, key):
        ''' I'm suppressing, so on_press must emit every key
        But, I start with an authentic and then a synthetic press
        The normal keys will do nothing, but the end keys trigger an expansion
        So I have to treat them differently 
        For normal keys, I emit the authentic and block the synthetic
        For end keys, I block the synthetic and emit the authentic 
        '''
        self.failsafe += 1
        if self.failsafe > 20:
           self._log.warning('stopping on fail safe')
           exit(1)

        # React to type of key 
        if not key in self.key_queue.end_keys:
            self._onpress_normal_key(key)
        else:
            self._onpress_end_key(key)

    def _onpress_normal_key(self, key):
        self._log.debug(f"onpress_normal for {key}")
        if not self.next_normal_key and self.blockable_normal_keys:
            self.next_normal_key = self.blockable_normal_keys.popleft()
            self._log.debug(f"Loaded up next normal key with {self.next_normal_key}")
        else:
            self._log.debug(f"No normal keys queued")

        if key != self.next_normal_key:
            self._log.debug(f"Emitting {key}")
            self.key_queue.push_keystroke(key)
            self.blockable_normal_keys.append(key)
            self._log.debug(f"Through keys are now {self.blockable_normal_keys}")
            self.controller.press(key)
            self.controller.release(key)
        else:
            self._log.debug(f"Blocking {key}")
            self.next_normal_key = ''

    def _onpress_end_key(self, key):
        self._log.debug(f"onpress_endkey for {key}")
        if not self.next_end_key and self.emitable_end_keys:
            self.next_end_key = self.emitable_end_keys.popleft()
            self._log.debug(f"Loaded up next end key with {self.next_end_key}")
        else:
            self._log.debug(f"No end keys queued")

        if key == self.next_end_key:
            self._log.debug(f"Emitting {key}")
            self.controller.press(key)
        else:
            self._log.debug(f"Blocking {key}")
            self.key_queue.push_keystroke(key)
            self.emitable_end_keys.append(key)
            self._log.debug(f"Through keys are now {self.emitable_end_keys}")
            self.next_end_key = ''

    def start_listener(self):
        listener = keyboard.Listener(
            on_press=self.on_press,
            suppress=True          # block the original hardware event
        )
        listener.start()          # runs in its own thread
        self._log.debug(f"Listener started as {listener}")
        return listener