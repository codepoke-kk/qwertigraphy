


from log_factory import get_logger
from vaulter import Vaulter

class Chorder:
    _log = get_logger('CHORD')
    _vaulter = Vaulter()

    def __init__(self):
        self._log.info('Initiated Chorder')

    def handle_token(self, token: dict):
        self._log.info(f"Handling token: {token}")
        # Here you would implement the logic to handle the chord token
        # For example, expanding it into a password or other sensitive information
        # This is a placeholder implementation
        if token['function'] == "output_base_password":
            self._vaulter.output_base_password()
        elif token['function'] == "output_base_username_password":
            self._vaulter.output_base_username_password()
        elif token['function'] == "new_base_password":
            self._vaulter.new_base_password()
        else:
            self._log.warning(f"Unknown token: {token}")