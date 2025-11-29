
from log_factory import get_logger
import keyboard 

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

    end_keys['tab'] = 1
    end_keys['space'] = 1
    end_keys['enter'] = 1

    def __init__(self, engine):
        self.engine = engine 
        self.keystroke_queue = []
        self._log.info('Initiated Key Input')

    def push_keystroke(self, key):
        self._log.debug(f"Pushing {key}")
        if key in self.end_keys:
            self._log.debug(f"Key {key} is an end key")
            self.engine.expand_queue(self.keystroke_queue, key)
            self.keystroke_queue = []
        else:
            if len(key) == 1:
                self._log.debug(f"Key {key} is a normal key")
                self.keystroke_queue.append(key)
                self.engine.display_hints(self.keystroke_queue)
            else:
                self._log.debug(f"Key {key} is a control key - ignoring")
        self._log.debug(f"Queue is now {self.keystroke_queue}")
