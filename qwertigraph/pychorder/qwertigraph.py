from key_queue import Key_Queue
from key_input import Key_Input
from engine import Expansion_Engine
from key_output import Key_Output

from pynput import keyboard
from functools import partial


# a thread‑safe list will act as our “queue”
keystroke_queue = []

def on_press(key):
    try:
        # regular character keys
        keystroke_queue.append(key.char)
    except AttributeError:
        # special keys (space, enter, backspace …)
        keystroke_queue.append(str(key))

def start_listener():
    listener = keyboard.Listener(on_press=on_press)
    listener.start()          # runs in its own thread
    return listener


def pop_keystrokes(n):
    """Return the last n keystrokes and remove them from the queue."""
    if n > len(keystroke_queue):
        return None
    # slice the tail, then truncate the list
    result = keystroke_queue[-n:]
    del keystroke_queue[-n:]
    return ''.join(result)

EXPANSIONS = {
    "brb": "be right back",
    "addr": "123 Main St., Springfield, USA",
    "sig": "Best regards,\nJohn Doe"
}
MAX_TRIGGER_LEN = max(len(k) for k in EXPANSIONS)   # longest trigger we care about
import time

def engine_loop(poll_interval=0.05):
    while True:
        # Look at the most recent characters (up to the longest trigger)
        tail = ''.join(keystroke_queue[-MAX_TRIGGER_LEN:])
        for trigger, expansion in EXPANSIONS.items():
            if tail.endswith(trigger):
                # We have a match – hand it off to the output component
                replace_trigger(trigger, expansion)
                break
        time.sleep(poll_interval)

        
from pynput.keyboard import Controller, Key

controller = Controller()

def replace_trigger(trigger, expansion):
    # 1️⃣ Erase the trigger
    for _ in range(len(trigger)):
        controller.press(Key.backspace)
        controller.release(Key.backspace)

    # 2️⃣ Type the expansion
    for char in expansion:
        # handle special keys like newline
        if char == '\n':
            controller.press(Key.enter)
            controller.release(Key.enter)
        else:
            controller.type(char)

    # Clean the queue of the consumed trigger
    # (pop_keystrokes already removed it, but we also clear any stray chars)
    # This is optional depending on how you manage the queue.


def on_activate_chord():
    print(f'Pressed ')

def on_activate_b1():
    print('b1 pressed')

def on_activate_b2():
    print('b2 pressed')

def universal_handler(name):
    """
    This is the single function that does the real work.
    `name` tells us which hot‑key fired.
    """
    print(f'Hot‑key "{name}" was pressed!')

hotkey_actions = {
    'b+1': partial(universal_handler, 'b1'),
    'b+2': partial(universal_handler, 'b2'),
    'b+3': partial(universal_handler, 'b3')
}

if __name__ == "__main__":
    
    # Start listening for keystrokes
    start_listener()

    print("starting")
    hotkey_listener = keyboard.GlobalHotKeys(hotkey_actions)
    hotkey_listener.start()

    print("started")
    

    # Run the matching engine in the main thread (or spin it off to another thread)
    try:
        engine_loop()
    except KeyboardInterrupt:
        print("\nStopped.")