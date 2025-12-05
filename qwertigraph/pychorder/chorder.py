


from log_factory import get_logger
from vaulter import Vaulter
from engine_signal_proxy import EngineSignalProxy

class Chorder:
    _log = get_logger('CHORD')

    def __init__(self, engine_signals: 'EngineSignalProxy') -> None:
        self.engine_signals = engine_signals
        self._vaulter = Vaulter(self.engine_signals)
        self._log.info('Initiated Chorder')

    def handle_token(self, token: dict):
        self._log.info(f"Handling token: {token}")
        # Here you would implement the logic to handle the chord token
        # For example, expanding it into a password or other sensitive information
        # This is a placeholder implementation
        if token['function'] == "output_password_a":
            self._vaulter.output_password('a')
        elif token['function'] == "output_username_password_a":
            self._vaulter.output_username_password('a')
        elif token['function'] == "output_username_a":
            self._vaulter.output_username('a')
        elif token['function'] == "output_password_b":
            self._vaulter.output_password('b')
        elif token['function'] == "output_username_password_b":
            self._vaulter.output_username_password('b')
        elif token['function'] == "output_username_b":
            self._vaulter.output_username('b')
        elif token['function'] == "output_password_c":
            self._vaulter.output_password('c')
        elif token['function'] == "output_username_password_c":
            self._vaulter.output_username_password('c')
        elif token['function'] == "output_username_c":
            self._vaulter.output_username('c')
        else:
            self._log.warning(f"Unknown token: {token}")
        
        self._log.debug(f"Handled token: {token}")