
from log_factory import get_logger
import time 

class Key_Queue:
    _log = get_logger('KEYQ') 
    # Keep separate lists of special, normal, and pause keys
    # But merge them into "end_keys" 
    stop_keys_special = {'Key.space': 1, 'Key.tab': 1, 'Key.enter': 1}
    # But also keep a combined list for lookups 
    end_keys = stop_keys_special 

    stop_keys_normal_str = '\'".,?!;:_{}()[]/\\+=|()@#$%^*<>' # Not: &
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
        self.start_stamp = time.monotonic()
        self._log.info('Initiated Key Queue')

    def push_keystroke(self, key):
        self._log.debug(f"Pushing {key}")
        # Reset the timer if the queue was empty AND it's been more than 5 seconds since the last send
        if not self.keystroke_queue:
            new_start_time = time.monotonic()
            if new_start_time - self.start_stamp > 5.0:
                self.start_stamp = time.monotonic()
            self._log.debug(f"Queue was empty, set start_stamp to {self.start_stamp}")

        if key in self.end_keys:
            self._log.debug(f"Key {key} is an end key")
            end_stamp = time.monotonic()
            self.engine.expand_queue(self.keystroke_queue, key, (end_stamp - self.start_stamp))
            # Reset the queue and timer
            self.start_stamp = end_stamp
            self.keystroke_queue = []
        else:
            if len(key) == 1:
                self._log.debug(f"Key {key} is a normal key")
                self.keystroke_queue.append(key)
                self.engine.display_hints(self.keystroke_queue)
            elif key == 'backspace':
                self._log.debug(f"Key {key} is backspace - removing last key if any")
                if self.keystroke_queue:
                    removed_key = self.keystroke_queue.pop()
                    self._log.debug(f"Removed key {removed_key} from queue")
                    self.engine.display_hints(self.keystroke_queue)
                else:
                    # In AHK, I tracked back through history to bring back previous qwerds
                    # I'm not going to do that here yet
                    self._log.debug(f"Queue is empty - nothing to remove")
            elif key in ['ctrl', 'right ctrl', 'left ctrl', 'alt', 'right alt', 'left alt',
                         'windows', 'right windows', 'left windows']:
                    # In AHK, I sent ctrl-. as '.'. I'm going to try not doing that here
                self.clear_queue(f"control key {key}")
            elif key in ['right', 'left', 'up', 'down',
                         'insert', 'delete', 'home', 'end', 'page up', 'page down']:
                    # In AHK, I sent ctrl-. as '.'. I'm going to try not doing that here
                self.clear_queue(f"navigation key {key}")
            else:
                self._log.debug(f"Key {key} is a control key - ignoring")
        self._log.debug(f"Queue is now {self.keystroke_queue}")

    def clear_queue(self, message='Unaccredited'):
        self._log.debug(f"Clearing key queue: {message}")
        self.keystroke_queue = []
        self.engine.display_hints(self.keystroke_queue)