
import keyboard
import threading

buffer = ""
suppress_flag = False

def on_key(e):
    global buffer, suppress_flag

    if e.event_type == 'down':
        if e.name in "ab" and not e.is_keypad:
            buffer += e.name
            suppress_flag = True
        elif e.name == "c" and not e.is_keypad:
            if buffer:
                keyboard.write(buffer + "c")
                buffer = ""
                suppress_flag = True
            else:
                suppress_flag = False
        elif e.name == "d" and not e.is_keypad:
            if buffer:
                keyboard.write("othertext")
                buffer = ""
                suppress_flag = True
            else:
                suppress_flag = False
        else:
            if buffer:
                keyboard.write(buffer)
                buffer = ""
            suppress_flag = False
    return not suppress_flag

hook = keyboard.hook(on_key, suppress=True)

try:
    keyboard.wait('esc') # Wait for the 'esc' key to exit the script
finally:
    keyboard.unhook(hook) # Remove the hook when the script is done