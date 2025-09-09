import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")          # <-- adjust path if needed

from log_factory import get_logger
from key_queue import Key_Queue
from key_input import Key_Input
from engine import Expansion_Engine
from key_output import Key_Output


if __name__ == "__main__":
    _log = get_logger("QW")
    _log.info("Here we are")
    key_output = Key_Output()
    engine = Expansion_Engine(key_output)
    key_queue = Key_Queue(engine)
    key_input = Key_Input(key_queue)

    key_input.start_listener()
    engine.engine_loop()
