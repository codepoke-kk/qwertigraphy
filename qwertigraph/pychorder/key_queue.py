
from log_factory import get_logger
import time 
from collections import deque

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
        self.keystroke_queue = deque()
        self.replay_queue = deque()
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
            replay_output = self.engine.expand_queue(self.keystroke_queue, key, (end_stamp - self.start_stamp))
            self.replay_queue.append(replay_output)
            # self._log.debug(f"Replay queue is {self.replay_queue}")
            # Reset the queue and timer
            self.start_stamp = end_stamp
            self.keystroke_queue = deque()
        else:
            if len(key) == 1:
                self._log.debug(f"Key {key} is a normal key")
                self.keystroke_queue.append(key)
                self.engine.display_hints(self.keystroke_queue)
            elif key == 'backspace':
                self._log.debug(f"Key {key} is backspace - removing last key if any")
                # When backspace is sent, keep track of what letters we have queued up 
                if self.keystroke_queue:
                    removed_key = self.keystroke_queue.pop()
                    self._log.debug(f"Removed key {removed_key} from queue")
                    self.engine.display_hints(self.keystroke_queue)
                else:
                    # If the queue is already empty, reload it from the replay queue so user can backspace through prior expansions
                    if self.replay_queue:
                        self.keystroke_queue.extend(self.replay_queue.pop()) 
                    self._log.debug(f"Queue is empty - reloaded from replay queue to {self.keystroke_queue}")
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
        self.keystroke_queue = deque()
        self.replay_queue = deque()
        self.start_stamp = time.monotonic()
        self.engine.display_hints(self.keystroke_queue)