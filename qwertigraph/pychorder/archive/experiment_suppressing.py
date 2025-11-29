import keyboard
import time

# -------------------------------------------------
# 1️⃣  Remap the physical Tab key to act like Space
# -------------------------------------------------
def _tab_to_space(event):
    """Replace Tab with Space and block the original Tab."""
    if event.event_type == 'down':
        keyboard.send('space')          # synthesize a Space press+release
    return False                         # suppress the original Tab
keyboard.hook_key('tab', _tab_to_space, suppress=True)

print("Remap active: pressing Tab now inserts a Space.")
time.sleep(5)   # give you a chance to try it manually

# -------------------------------------------------
# 2️⃣  Emit a **real** Tab character (text insertion)
# -------------------------------------------------
print("\nInserting a literal Tab character with keyboard.write('\\t'):")
keyboard.write('\t')          # writes the Unicode U+0009 directly
time.sleep(1)

# -------------------------------------------------
# 3️⃣  Emit a **raw Tab key event** (scan‑code) – bypasses the remap
# -------------------------------------------------
# Get the scan code that the library uses for the Tab key on this platform
tab_scancode = keyboard.key_to_scan_codes('tab')[0]   # returns a list; pick the first

print("\nEmitting a raw Tab key press using its scan code:")
# Option A – public API (press + release)
# keyboard.press(scan_code=tab_scancode)
# keyboard.release(scan_code=tab_scancode)

# Option B – one‑shot private helper (does the same thing)
keyboard._send_scancode(tab_scancode)   # uncomment if you prefer this style

print("\nPress ESC to quit.")
keyboard.wait('esc')