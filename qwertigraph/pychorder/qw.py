import os, sys 
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")          # <-- adjust path if needed

from log_factory import get_logger
from key_queue import Key_Queue
from key_input import Key_Input
from engine import Expansion_Engine
from key_output import Key_Output
from scribe import Scribe


if __name__ == "__main__":
    _log = get_logger("QW")
    _log.info("Launching Qwerd Engine")
    ### Ownership chain is back to front 
    # Scribe has the last function, recording what happened 
    scribe = Scribe()
    # Pass scribe to key output that makes it happen 
    key_output = Key_Output(scribe)
    # Pass key output to engine that decides what should happen 
    engine = Expansion_Engine(key_output)
    # Pass engine to queue that knows when a thing should happen 
    key_queue = Key_Queue(engine)
    # Pass queue to input, that gathers what's requested to happen 
    key_input = Key_Input(key_queue)
    # Start the listener, that collects the requests 
    # key_input.start_listener()
    # Start the loop with the Scribe to tell me what's happened 
    # engine.engine_loop()
