import os
from log_factory import get_logger

class KeyInput:
    _log = get_logger('KEYIN')

    def __init__(self, key_queue):
        self.key_queue = key_queue
        self._log.info('Initiated Key Input')
        self.controller = keyboard.Controller()   # for re‑emitting keys

    # ------------------------------------------------------------------
    # 3️⃣  Callback that runs for every key press
    # ------------------------------------------------------------------
    def on_press(self, key):
        """Called by pynput for *every* key press."""
        self._log.debug(f"Pressed {key}")

        # --------------------------------------------------------------
        # Is this an end‑key (expansion trigger)?
        # --------------------------------------------------------------
        if key in END_KEYS:
            self._log.debug("End‑key detected – suppressing and expanding")
            self._handle_end_key(key)   # run your expansion routine
            # Returning True (or nothing) tells the listener we’re done.
            # Because the listener was created with suppress=True,
            # the original key never reaches the target.
            return True

        # --------------------------------------------------------------
        # Normal key → forward it unchanged
        # --------------------------------------------------------------
        self._forward_normal_key(key)
        self.key_queue.push_keystroke(key)   # keep your queue semantics
        return True   # keep listening

    # ------------------------------------------------------------------
    # 4️⃣  Forward a regular key by synthesising it again
    # ------------------------------------------------------------------
    def _forward_normal_key(self, key):
        """Re‑emit the key so the active window sees it."""
        # `Controller.press`/`release` works for both special Keys and
        # printable characters (KeyCode objects).
        self.controller.press(key)
        self.controller.release(key)

    # ------------------------------------------------------------------
    # 5️⃣  What to do when an end‑key is pressed
    # ------------------------------------------------------------------
    def _handle_end_key(self, key):
        """
        Replace the trigger with the expanded text.
        Example: Tab → the word “foobar ” (note the trailing space).
        """
        # ----- 5.1  Choose the expansion ---------------------------------
        # In a real program you would look up the expansion based on the
        # surrounding buffer, a shortcut table, etc.
        expanded_word = "foobar "          # <-- replace with your logic

        # ----- 5.2  Send the expansion ------------------------------------
        for ch in expanded_word:
            self.controller.type(ch)

        # If you need to pad to a column, compute the needed spaces here
        # and type them as well:
        #   needed = desired_col - (cursor_pos % desired_col)
        #   self.controller.type(' ' * needed)

    # ------------------------------------------------------------------
    # 6️⃣  Start the listener (suppression enabled)
    # ------------------------------------------------------------------
    def start_listener(self):
        listener = keyboard.Listener(
            on_press=self.on_press,
            suppress=True          # <‑‑ blocks the *original* keystroke
        )
        listener.start()          # runs in its own thread
        self._log.debug(f"Listener started as {listener}")
        return listener