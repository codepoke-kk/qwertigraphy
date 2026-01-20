import logging
from log_factory import get_logger   # keep your existing logger factory
import keyboard
import datetime

class Macros:
    _log: logging.Logger = get_logger("MACRO")

    def __init__(self) -> None:
        self._log.info("Initiated Helper")

    # -----------------------------------------------------------------
    # Public helpers that other parts of the program call
    # -----------------------------------------------------------------
    def output_date(self) -> None:
        today = datetime.datetime.now().strftime("%m/%d/%Y")
        self._log.debug(f"Writing today as {today}")
        keyboard.write(today)        
        
    def output_time(self) -> None:
        now = datetime.datetime.now().strftime("%H:%M:%S")
        self._log.debug(f"Writing now as {now}")
        keyboard.write(now)    
