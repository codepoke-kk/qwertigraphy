# scribe.py
import multiprocessing
import time
from typing import List

# ----------------------------------------------------------------------
# Helper that launches the UI process (coach)
# ----------------------------------------------------------------------
def _run_coach_process():
    """Entry point executed inside the child process."""
    from coach_ui import start_coach_process
    start_coach_process()          # blocks forever (Qt event loop)

def launch_coach():
    """
    Starts the coach process using the 'spawn' start method (required on Windows).
    Returns the Process object so we can terminate it later.
    """
    ctx = multiprocessing.get_context('spawn')
    proc = ctx.Process(target=_run_coach_process,
                       daemon=True,
                       name='CoachProcess')
    proc.start()
    return proc


# ----------------------------------------------------------------------
# Scribe – the class that wants to control the UI
# ----------------------------------------------------------------------
class Scribe:
    _coach_proxy = None          # will hold the Manager proxy
    _coach_process = None

    def __init__(self) -> None:
        self._start_coach()
        # Small pause to let the manager finish its handshake
        time.sleep(0.5)

    def _start_coach(self):
        """Spawn the UI process and obtain a proxy to the Coach dispatcher."""
        self._coach_process = launch_coach()

        # --------------------------------------------------------------
        # Connect to the same address/authkey we used in coach_viewport.start_coach_process
        # --------------------------------------------------------------
        from multiprocessing.managers import BaseManager

        class CoachClient(BaseManager):
            pass

        CoachClient.register('Coach')
        self._coach_proxy = CoachClient(address=('localhost', 6000),
                                        authkey=b'coach-secret')
        self._coach_proxy.connect()
        self._coach = self._coach_proxy.Coach()   # <-- proxy to the dispatcher

        # --------------------------------------------------------------
        # Initial UI configuration (calls travel across processes)
        # --------------------------------------------------------------
        self._coach.set_upper_text("Shorthand Tape")
        self._coach.set_lower_text("Hints")

    # ------------------------------------------------------------------
    # Convenience wrappers that forward to the UI (same signatures as before)
    # ------------------------------------------------------------------
    def set_upper_text(self, txt: str):
        self._coach.set_upper_text(txt)

    def set_lower_text(self, txt: str):
        self._coach.set_lower_text(txt)

    def append_to_upper(self, line: str):
        self._coach.append_to_upper(line)

    def append_to_lower(self, line: str):
        self._coach.append_to_lower(line)

    # ------------------------------------------------------------------
    # Clean‑up
    # ------------------------------------------------------------------
    def shutdown(self):
        if self._coach_process and self._coach_process.is_alive():
            # Ask the UI to close gracefully (optional)
            # self._coach.close_viewport()   # you could expose such a slot
            self._coach_process.terminate()
            self._coach_process.join()


# ----------------------------------------------------------------------
# Demo – run Scribe and interact with the UI while the main thread does work
# ----------------------------------------------------------------------
if __name__ == '__main__':
    s = Scribe()
    for i in range(50):
        s.append_to_upper(f"Upper line {i+1}")
        s.append_to_lower(f"Lower line {i+1}")
        time.sleep(.1)

    # Keep the UI alive a bit longer so you can see the result
    time.sleep(3)
    s.shutdown()