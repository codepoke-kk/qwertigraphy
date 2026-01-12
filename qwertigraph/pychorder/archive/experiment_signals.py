# demo.py ---------------------------------------------------------------
import sys, threading
from PyQt6.QtWidgets import QApplication, QMainWindow, QTextEdit, QVBoxLayout, QWidget
from PyQt6.QtCore import QObject, pyqtSignal, QThread, QCoreApplication
from pynput import keyboard   # pip install pynput

# ----------------------------------------------------------------------
def log_thread_context(where: str) -> None:
    qt_thread = QThread.currentThread()
    is_gui = qt_thread == QCoreApplication.instance().thread()
    py_thread = threading.current_thread()
    print(
        f"[{where}] Qt thread id={int(qt_thread.currentThreadId())} "
        f"(GUI={is_gui}), Python name='{py_thread.name}'"
    )

# ----------------------------------------------------------------------
class UiBridge(QObject):
    coachLowerChanged = pyqtSignal(str)

# ----------------------------------------------------------------------
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Keyboard‑hook demo")
        central = QWidget()
        self.setCentralWidget(central)
        lay = QVBoxLayout(central)

        self.lower = QTextEdit()
        lay.addWidget(self.lower)

        # Bridge lives in the GUI thread
        self.bridge = UiBridge()
        self.bridge.coachLowerChanged.connect(self.set_coach_lower)

        # Start the keyboard listener (runs in its own thread)
        self.listener = keyboard.Listener(on_press=self._on_key)
        self.listener.start()

    # ------------------------------------------------------------------
    def _on_key(self, key):
        """Callback executed in the hook's thread."""
        log_thread_context("hook_callback")
        try:
            txt = f"{key.char}" if hasattr(key, "char") else f"{key}"
        except Exception:
            txt = f"{key}"
        # Emit the signal – Qt will queue it to the GUI thread
        self.bridge.coachLowerChanged.emit(txt)

    # ------------------------------------------------------------------
    def set_coach_lower(self, text: str):
        """Runs on the GUI thread (because of the queued signal)."""
        log_thread_context("set_coach_lower")
        self.lower.setPlainText(text)
        self.lower.verticalScrollBar().setValue(
            self.lower.verticalScrollBar().minimum()
        )

# ----------------------------------------------------------------------
def main():
    app = QApplication(sys.argv)
    win = MainWindow()
    win.resize(400, 200)
    win.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()