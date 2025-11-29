
import keyboard
import threading
import time

buffer = ""
dict = {
    'gr': 'great',
    'br': 'bring'
}

def holder():
    print("holding")

def on_key(e):
    global buffer

    if e.event_type == 'down':
        # time.sleep(0.5)
        if e.name == "tab":
            print(f"I see a {e.name} key")
            if buffer in dict:
                for char in buffer:
                    # time.sleep(0.5)
                    holder()
                    keyboard.send("backspace")  # delete the buffer
                keyboard.write(dict[buffer])  # write the expansion
            else:
                keyboard.write(buffer)
            buffer = ''
        else:
            buffer += e.name
    return True

hook = keyboard.hook(on_key, suppress=True)

try:
    keyboard.wait('esc') # Wait for the 'esc' key to exit the script
finally:
    keyboard.unhook(hook) # Remove the hook when the script is done