
from log_factory import get_logger
from pynput import keyboard 

class Key_Queue:
    _log = get_logger('KEYQ') 
    # Keep separate lists of special, normal, and pause keys
    # But merge them into "end_keys" 
    stop_keys_special = {'Key.space': 1, 'Key.tab': 1, 'Key.enter': 1}
    # But also keep a combined list for lookups 
    end_keys = stop_keys_special 

    stop_keys_normal_str = '\'".,?!;:_{}()[]/\+=|()@#$%^*<>' # Not: &
    stop_keys_normal_array = list(stop_keys_normal_str)
    stop_keys_normal = {}
    for end_key in stop_keys_normal_array:
        stop_keys_normal[end_key] = 1
        end_keys[end_key] = 1

    pause_keys_normal_str = '\'-' 
    pause_keys_normal_array = list(pause_keys_normal_str)
    pause_keys_normal = {}
    for end_key in pause_keys_normal_array:
        pause_keys_normal[end_key] = 1
        end_keys[end_key] = 1

    def __init__(self, engine):
        self.engine = engine 
        self.keystroke_queue = []
        self._log.info('Initiated Key Input')

    def push_keystroke(self, key):
        self._log.debug(f"Pushing {key}")
        self._log.debug(f"Queue starting as {self.keystroke_queue}")
        if isinstance(key, keyboard.KeyCode):
            # Regular character key
            if key.char in self.end_keys:
                self._log.debug(f"Draining queue on plain key {key}")
                self.engine.expand_queue(self.keystroke_queue, key)
                self.keystroke_queue = []
            else:
                self._log.debug(f"Queuing {key}")
                self.keystroke_queue.append(key)
        else:
            # Special key (Key.xxx) and don't end on all special characters 
            if str(key) == 'Key.backspace':
                self._log.debug(f"{key} sent - backing up queue")
                self.keystroke_queue = self.keystroke_queue[0:-1]
            elif str(key) in self.end_keys:
                self._log.debug(f"Draining queue on special key {key}")
                self.engine.expand_queue(self.keystroke_queue, key)
                self.keystroke_queue = []

        self._log.debug(f"Queue is now {self.keystroke_queue}")

'''
    def pop_keystroke(self):
        self._log.debug(f"Popping")
        if not len(self.keystroke_queue):
            return None
        # slice the tail, then truncate the list
        result = self.keystroke_queue[-1]
        del self.keystroke_queue[-1]
        self._log.debug(f"Returning {result} and keeping {self.keystroke_queue}")
        return result 
          
    def pop_keystrokes(self, n):
        """Return the last n keystrokes and remove them from the queue."""
        if n > len(self.keystroke_queue):
            return None
        # slice the tail, then truncate the list
        result = self.keystroke_queue[-n:]
        del self.keystroke_queue[-n:]
        return ''.join(result)
'''