import logging
from log_factory import get_logger   # keep your existing logger factory
import keyboard
import datetime

class Helper:
    _log: logging.Logger = get_logger("HELPR")

    def __init__(self) -> None:
        self._log.info("Initiated Helper")

    # -----------------------------------------------------------------
    # Public helpers that other parts of the program call
    # -----------------------------------------------------------------
    def output_date(self) -> None:
        today = datetime.datetime.now().strftime("%m/%d/%Y")
        # Assuming you use the same `keyboard` library you used before:
        import keyboard
        keyboard.write(today)        
        
    def output_time(self) -> None:
        now = datetime.datetime.now().strftime("%H:%M:%S")
        import keyboard
        keyboard.write(now)
