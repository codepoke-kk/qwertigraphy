import logging
from log_factory import get_logger   # keep your existing logger factory
from engine_signal_proxy import EngineSignalProxy
import keyboard

class Vaulter:
    _log: logging.Logger = get_logger("VAULT")

    def __init__(self, engine_signals: 'EngineSignalProxy') -> None:
        self.engine_signals = engine_signals
        self._credentials = {'a_user': '', 'a_pass': '', 'b_user': '', 'b_pass': '', 'c_user': '', 'c_pass': ''}
        self._log.info("Initiated Vaulter")

    # -----------------------------------------------------------------
    # Public helpers that other parts of the program call
    # -----------------------------------------------------------------
    def output_username(self, tag) -> None:
        key = f'{tag}_user'
        self._log.info(f"Writing: {key}")
        if key not in self._credentials:
            self._log.error(f"No username found for tag: {tag}")
            return
        keyboard.write(self._credentials[key])
        
    def output_password(self, tag) -> None:
        key = f'{tag}_pass'
        self._log.info(f"Writing password: {key}")
        if key not in self._credentials:
            self._log.error(f"No password found for tag: {tag}")
            return
        keyboard.write(self._credentials[key])

    def output_username_password(self, tag) -> None:
        user_key = f'{tag}_user'
        pass_key = f'{tag}_pass'
        self._log.info(f"Writing username password: {user_key}/{pass_key}")
        if user_key not in self._credentials or pass_key not in self._credentials:
            self._log.error(f"No username/password found for tag: {tag}")
            return 
        keyboard.write(self._credentials[user_key])
        keyboard.write('\t')  # Tab to password field   
        keyboard.write(self._credentials[pass_key])

    def update_credentials(self, new_credentials: dict) -> None:
        self._log.info("Received new credentials dict")
        self._credentials = new_credentials

    # -----------------------------------------------------------------
    # Nice representation – never prints the real credential
    # -----------------------------------------------------------------
    def __repr__(self) -> str:
        uname = 'playing'
        pw_len = 7
        return f"<Vaulter username={uname!r} credential_length={pw_len}>"