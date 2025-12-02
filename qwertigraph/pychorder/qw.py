# GUI imports
import sys
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QPushButton,
)
from PyQt6.QtCore import Qt, pyqtSlot

# Engine imports
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")          # <-- adjust path if needed

from log_factory import get_logger
from listener_thread import ListenerThread

_QW_LOG = get_logger("QW") 

class MainWindow(QMainWindow):
    """Main application window."""

    def __init__(self) -> None:
        super().__init__()

        self.setWindowTitle("Qwertigraph - Engine Control")
        self.resize(300, 180)    

        central = QWidget(self)
        self.setCentralWidget(central)

        v_layout = QVBoxLayout()
        v_layout.setAlignment(Qt.AlignmentFlag.AlignTop)   
        central.setLayout(v_layout)

        # ---------------------------------------------------------
        # 1️⃣  Two labels, one above the other
        # ---------------------------------------------------------
        self.lbl_title = QLabel("Qwertigraph Engine", self)
        self.lbl_title.setAlignment(Qt.AlignmentFlag.AlignLeft)
        self.lbl_title.setStyleSheet("font-weight: bold; font-size: 14pt;")
        v_layout.addWidget(self.lbl_title)

        self.lbl_speed = QLabel("Speed: 25", self)
        self.lbl_speed.setAlignment(Qt.AlignmentFlag.AlignLeft)
        self.lbl_speed.setStyleSheet("color: gray;")
        v_layout.addWidget(self.lbl_speed)

        # ---------------------------------------------------------
        # 2️⃣  Horizontal layout for the two buttons
        # ---------------------------------------------------------
        h_btns = QHBoxLayout()
        h_btns.setSpacing(20)           
        v_layout.addLayout(h_btns)

        self.btn_start = QPushButton("Start Engine", self)
        self.btn_start.clicked.connect(self.start_engine)
        h_btns.addWidget(self.btn_start)

        self.btn_stop = QPushButton("Stop Engine", self)
        self.btn_stop.clicked.connect(self.stop_engine)
        h_btns.addWidget(self.btn_stop)

        # ---------------------------------------------------------
        # Optional: make the Start button disabled initially (engine on)
        # ---------------------------------------------------------
        self.btn_start.setEnabled(False)
        self.btn_stop.setEnabled(True)
        
        # ---------------------------------------------------------
        # 3️⃣  Start the listener in a background QThread
        # ---------------------------------------------------------
        # We do **not** pass a pre‑built queue here – the thread builds its own
        # internal pipeline.  If you need to talk to the listener later
        # (e.g. push a command), you can expose `self.listener_thread.key_queue`
        # as a public attribute.
        self.listener_thread = ListenerThread(key_queue=None)   # key_queue arg unused
        self.listener_thread.signals.speed_changed.connect(self.update_speed_label)
        self.listener_thread.signals.engine_started.connect(self.on_engine_started)
        self.listener_thread.signals.engine_stopped.connect(self.on_engine_stopped)

        # Start the thread – it will immediately spin up the keyboard listener.
        self.listener_thread.start()

        _QW_LOG.info("Started Engine in startup")

    # -----------------------------------------------------------------
    # Slot implementations – replace with your real logic later
    # -----------------------------------------------------------------
    def start_engine(self) -> None:
        """Called when the user clicks “Start Engine”. """
        _QW_LOG.info("Starting Engine")
        self.btn_start.setEnabled(False)
        self.btn_stop.setEnabled(True)
        # TODO: insert the code that actually starts your engine here

    def stop_engine(self) -> None:
        """Called when the user clicks “Stop Engine”. """
        _QW_LOG.info("Stopping Engine")
        self.btn_start.setEnabled(True)
        self.btn_stop.setEnabled(False)
        # TODO: insert the code that actually stops your engine here

    # -----------------------------------------------------------------
    # Slots that react to signals emitted from the listener thread
    # -----------------------------------------------------------------
    @pyqtSlot(int)
    def update_speed_label(self, new_speed: int) -> None:
        """Update the “Speed:” label when the engine reports a new speed."""
        self.lbl_speed.setText(f"Speed: {new_speed}")

    @pyqtSlot()
    def on_engine_started(self) -> None:
        """Optional: react to a signal that the engine has started."""
        _QW_LOG.info("Engine reported STARTED (via signal)")

    @pyqtSlot()
    def on_engine_stopped(self) -> None:
        """Optional: react to a signal that the engine has stopped."""
        _QW_LOG.info("Engine reported STOPPED (via signal)")
    # -----------------------------------------------------------------
    # Clean shutdown – called automatically when the window closes
    # -----------------------------------------------------------------
    def closeEvent(self, event):
        """Qt calls this when the user closes the main window."""
        _QW_LOG.info("MainWindow closeEvent – shutting down listener thread")
        # Ask the listener to stop (if it hasn't already)
        self.listener_thread.request_stop()
        # Wait for the thread to finish (with a timeout so we don't hang forever)
        self.listener_thread.quit()
        self.listener_thread.wait(3000)   # wait up to 3 seconds
        _QW_LOG.info("Listener thread terminated – exiting app")
        super().closeEvent(event)

# -----------------------------------------------------------------
# Boilerplate to launch the application
# -----------------------------------------------------------------
def main() -> None:
    _QW_LOG.info("Launching Qwertigraph Engine (main())")
    app = QApplication(sys.argv)

    # (optional) set a modern Qt style – you can pick any you like
    app.setStyle("Fusion")

    win = MainWindow()
    win.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()