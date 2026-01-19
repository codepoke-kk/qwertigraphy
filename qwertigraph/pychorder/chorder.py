'''
Central logic for processing chords.
key_input.py defines the chord listeners 
comms_proxy.py handles communication between UI and engine
macros.py defines functions called by chords
vaulter.py handles secure storage and retrieval of credentials
'''


from log_factory import get_logger
from functools import partial

from macros import Macros
from vaulter import Vaulter
from comms_proxy import Comms_Proxy

class Chorder:
    _log = get_logger('CHORD')

    def __init__(self, comms_proxy) -> None:
        self.comms_proxy = comms_proxy # Unused??
        self.vaulter = Vaulter(self.comms_proxy)
        self._macros = Macros()
        self._func_map = {
            # ── time and date helpers ───────────────────
            "output_time": self._macros.output_time,    
            "output_date": self._macros.output_date,    

            # -- UI Helpers ─────────────────────────
            "gregg_dict_lookup_word": self.comms_proxy.signal_gregg_dict_lookup_word,
            "focus_coach": self.comms_proxy.signal_focus_coach,

            # ── password helpers ───────────────────────
            "output_password_a": partial(self.vaulter.output_password, "a"),
            "output_password_b": partial(self.vaulter.output_password, "b"),
            "output_password_c": partial(self.vaulter.output_password, "c"),

            # ── username+password helpers ───────────────
            "output_username_password_a": partial(self.vaulter.output_username_password, "a"),
            "output_username_password_b": partial(self.vaulter.output_username_password, "b"),
            "output_username_password_c": partial(self.vaulter.output_username_password, "c"),

            # ── username only helpers ───────────────────
            "output_username_a": partial(self.vaulter.output_username, "a"),
            "output_username_b": partial(self.vaulter.output_username, "b"),
            "output_username_c": partial(self.vaulter.output_username, "c"),
        }

        self._log.info('Initiated Chorder')

    def handle_token(self, token: dict):
        self._log.info(f"Handling token: {token}")
        func = self._func_map.get(token.get("function"))
        if func is None:
            self._log.warning(f"Unknown token: {token}")
            return

        # Call the bound callable – no need to pass the argument again.
        func()
        
        self._log.debug(f"Handled token: {token}")

    def vaulter_update_credentials(self, credentials):
        self.vaulter.update_credentials(credentials)