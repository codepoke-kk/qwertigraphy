
import sys
import threading
import queue   # standard library, works inside a single process
from multiprocessing.managers import BaseManager

# ----------------------------------------------------------------------
# Qt imports
# ----------------------------------------------------------------------
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QTextEdit
from PyQt6.QtCore import Qt, QTimer

# ----------------------------------------------------------------------
# The real UI widget (runs in the main thread)
# ----------------------------------------------------------------------
class Coach_Viewport(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Coach")
        self.resize(180, 600)               # width=100, height=600 (pixels)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)   # no extra margins
        layout.setSpacing(0)                   # panes touch each other

        self.upper = QTextEdit(self)
        self._configure_text_edit(self.upper)
        layout.addWidget(self.upper)
        self.lower = QTextEdit(self)
        self._configure_text_edit(self.lower)
        layout.addWidget(self.lower)

    @staticmethod
    def _configure_text_edit(edit: QTextEdit):
        # print(f"Configuring new pane {edit}")
        edit.setReadOnly(False)                     # allow programmatic writes
        # In Qt6 the wrap mode enum lives under LineWrapMode
        edit.setLineWrapMode(QTextEdit.LineWrapMode.NoWrap)
        # Scroll‑bar policies are now under Qt.ScrollBarPolicy
        edit.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOn)
        edit.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        edit.setStyleSheet(
            """
            QTextEdit {
                background-color: #fafafa;
                font-family: Consolas, monospace;
                font-size: 10pt;
                padding: 2px;
            }
            """
        )
        # print(f"Configured pane {edit}")

    # ------------------------------------------------------------------
    # These are *internal* helpers that the dispatcher will call.
    # ------------------------------------------------------------------
    def _set_upper_text(self, txt: str):
        self.upper.setPlainText(txt)
        self.upper.verticalScrollBar().setValue(self.upper.verticalScrollBar().maximum())

    def _set_lower_text(self, txt: str):
        # print(f"Setting lower text to: {txt}")
        self.lower.setPlainText(txt)
        self.lower.verticalScrollBar().setValue(self.lower.verticalScrollBar().minimum())

    def _append_to_upper(self, line: str):
        self.upper.append(line)
        self.upper.verticalScrollBar().setValue(self.upper.verticalScrollBar().maximum())

    def _append_to_lower(self, line: str):
        # print(f"Appending to lower: {line}")
        self.lower.append(line)
        self.lower.verticalScrollBar().setValue(self.lower.verticalScrollBar().minimum())


# ----------------------------------------------------------------------
# Dispatcher – lives in the same process, but its *public* methods are
# called from the manager thread.  They only put a command on a queue.
# ----------------------------------------------------------------------
class CoachDispatcher:
    """
    A very small, thread‑safe façade.  The manager exposes this class.
    Each method enqueues a (method_name, args, kwargs) tuple.
    The GUI thread consumes the queue and calls the real widget.
    """
    def __init__(self, widget: Coach_Viewport, cmd_queue: queue.Queue):
        self._widget = widget
        self._q = cmd_queue

    # ---- Public API (exactly the names you want to expose) ----
    def set_upper_text(self, txt: str):
        self._q.put(('set_upper_text', (txt,), {}))

    def set_lower_text(self, txt: str):
        self._q.put(('set_lower_text', (txt,), {}))

    def append_to_upper(self, line: str):
        self._q.put(('append_to_upper', (line,), {}))

    def append_to_lower(self, line: str):
        # print(f"Dispatcher enqueueing append_to_lower: {line}")
        self._q.put(('append_to_lower', (line,), {}))


# ----------------------------------------------------------------------
# Manager plumbing – we register the *dispatcher*, not the widget itself.
# ----------------------------------------------------------------------
class CoachManager(BaseManager):
    pass


def _run_manager_server(address, authkey, ready_evt, dispatcher):
    """
    Runs the manager server in a *background* thread.
    The callable simply returns the already‑created dispatcher instance.
    """
    CoachManager.register(
        'Coach',
        callable=lambda: dispatcher,
        exposed=[
            'set_upper_text',
            'set_lower_text',
            'append_to_upper',
            'append_to_lower',
        ]
    )
    mgr = CoachManager(address=address, authkey=authkey)
    server = mgr.get_server()
    ready_evt.set()                # tell the main thread we are listening
    server.serve_forever()         # blocks this thread for the life of the process


def start_coach_process(
        address=('localhost', 6000),
        authkey=b'coach-secret'
    ) -> None:
    """
    Entry point that the parent process invokes (via multiprocessing.Process).
    1️⃣ Build the UI (main thread).  
    2️⃣ Spin up a manager server in a *daemon* thread.  
    3️⃣ Run the Qt event loop (blocks until the window closes).
    """
    # --------------------------------------------------------------
    # 1️⃣ GUI – must be created in the main thread of this process
    # --------------------------------------------------------------
    app = QApplication(sys.argv)
    coach_widget = Coach_Viewport()
    coach_widget.show()

    # --------------------------------------------------------------
    # 2️⃣ Command queue + dispatcher (both live in the main thread)
    # --------------------------------------------------------------
    cmd_q = queue.Queue()
    dispatcher = CoachDispatcher(coach_widget, cmd_q)

    # --------------------------------------------------------------
    # 3️⃣ Manager server in a helper thread
    # --------------------------------------------------------------
    ready_evt = threading.Event()
    mgr_thread = threading.Thread(
        target=_run_manager_server,
        args=(address, authkey, ready_evt, dispatcher),
        daemon=True,
        name='Coach‑Manager‑Thread'
    )
    mgr_thread.start()
    ready_evt.wait()   # make sure the server is listening before we continue

    # --------------------------------------------------------------
    # 4️⃣ Periodic timer that drains the command queue **in the GUI thread**
    # --------------------------------------------------------------
    def process_queue():
        """Consume all pending commands and call the real widget."""
        while True:
            try:
                meth_name, args, kwargs = cmd_q.get_nowait()
            except queue.Empty:
                break
            # Resolve the private method on the widget and call it
            # (the widget methods are deliberately prefixed with '_' to avoid
            # accidental external usamiable
            # print(f"Processing command: {meth_name} with args={args} kwargs={kwargs}")
            real_method = getattr(coach_widget, f'_{meth_name}')
            real_method(*args, **kwargs)

    timer = QTimer()
    timer.timeout.connect(process_queue)
    timer.start(30)          # check roughly every 30 ms (adjust as needed)

    # --------------------------------------------------------------
    # 5️⃣ Run the Qt event loop (this is the only blocking call)
    # --------------------------------------------------------------
    sys.exit(app.exec())