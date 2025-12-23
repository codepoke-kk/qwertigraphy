# GUI imports
import sys
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
    QLabel, QPushButton, QLineEdit, QGridLayout
)
from PyQt6.QtCore import Qt, pyqtSlot, pyqtSignal, QObject
from PyQt6.QtGui import QIcon

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
    # Signal emitted by the listener when it needs the credentials.
    # The listener sends a request; the GUI replies with the data.
    get_credentials = pyqtSignal(dict)         # dict contains the values

    def __init__(self) -> None:
        super().__init__()

        # Build the UI itself 
        self.setWindowTitle("Qwertigraph - Engine Control")
        icon_path = Path(__file__).with_name("coach.ico")   # same folder as script
        if icon_path.is_file():
            self.setWindowIcon(QIcon(str(icon_path)))
        else:
            print(f"⚠️  Icon not found: {icon_path}")
        self.resize(300, 180)    

        central = QWidget(self)
        self.setCentralWidget(central)

        v_layout = QVBoxLayout()
        v_layout.setAlignment(Qt.AlignmentFlag.AlignTop)   
        central.setLayout(v_layout)

        # Title
        self.lbl_title = QLabel("Qwertigraph Engine", self)
        self.lbl_title.setAlignment(Qt.AlignmentFlag.AlignLeft)
        self.lbl_title.setStyleSheet("font-weight: bold; font-size: 14pt;")
        v_layout.addWidget(self.lbl_title)

        # Performance label 
        self.lbl_performance = QLabel("Performance", self)
        self.lbl_performance.setAlignment(Qt.AlignmentFlag.AlignLeft)
        self.lbl_performance.setStyleSheet("color: gray;")
        v_layout.addWidget(self.lbl_performance)

        # Control buttons 
        h_btns = QHBoxLayout()
        h_btns.setSpacing(20)           
        v_layout.addLayout(h_btns)

        self.btn_start = QPushButton("Start Engine", self)
        self.btn_start.clicked.connect(self.start_engine)
        h_btns.addWidget(self.btn_start)

        self.btn_stop = QPushButton("Stop Engine", self)
        self.btn_stop.clicked.connect(self.stop_engine)
        h_btns.addWidget(self.btn_stop)

        self.btn_credentials = QPushButton("Update Credentials", self)
        self.btn_credentials.clicked.connect(self.updated_credentials)
        h_btns.addWidget(self.btn_credentials)


        # Credential input fields
        cred_grid = QGridLayout()
        cred_grid.setHorizontalSpacing(10)
        cred_grid.setVerticalSpacing(5)

        # Row 0 – Credential A
        cred_grid.addWidget(QLabel("Credential A:", self), 0, 0)
        self.le_user_a = QLineEdit(self)          # username field
        cred_grid.addWidget(self.le_user_a, 0, 1)
        self.le_pass_a = QLineEdit(self)          # password field
        self.le_pass_a.setEchoMode(QLineEdit.EchoMode.Password)
        cred_grid.addWidget(self.le_pass_a, 0, 2)

        # Row 1 – Credential B
        cred_grid.addWidget(QLabel("Credential B:", self), 1, 0)
        self.le_user_b = QLineEdit(self)
        cred_grid.addWidget(self.le_user_b, 1, 1)
        self.le_pass_b = QLineEdit(self)
        self.le_pass_b.setEchoMode(QLineEdit.EchoMode.Password)
        cred_grid.addWidget(self.le_pass_b, 1, 2)

        # Row 2 – Credential C
        cred_grid.addWidget(QLabel("Credential C:", self), 2, 0)
        self.le_user_c = QLineEdit(self)
        cred_grid.addWidget(self.le_user_c, 2, 1)
        self.le_pass_c = QLineEdit(self)
        self.le_pass_c.setEchoMode(QLineEdit.EchoMode.Password)
        cred_grid.addWidget(self.le_pass_c, 2, 2)

        # Add the grid to the main vertical layout
        v_layout.addLayout(cred_grid)
        # ---------------------------------------------------------
        # Optional: make the Start button disabled initially (engine on)
        # ---------------------------------------------------------
        self.btn_start.setEnabled(False)
        self.btn_stop.setEnabled(True)
        
        ### Listener configuration 
        # Enable the listener to forward messages back from the engine to the GUI
        self.listener_thread = ListenerThread() 
        self.listener_thread.signals.performance_updated.connect(self.update_performance_label)
        self.listener_thread.signals.engine_started.connect(self.on_engine_started)
        self.listener_thread.signals.engine_stopped.connect(self.on_engine_stopped)

        # Start the thread – it will immediately spin up the keyboard listener.
        self.listener_thread.start()

        _QW_LOG.info("Started Engine in startup")

    # Signal the listener when the user clicks Start/Stop
    def start_engine(self) -> None:
        """Called when the user clicks “Start Engine”. """
        _QW_LOG.info("Starting Engine")

        self.listener_thread.signals.start_requested.emit()

    def stop_engine(self) -> None:
        """Called when the user clicks “Stop Engine”. """
        _QW_LOG.info("Stopping Engine")
        
        self.listener_thread.signals.stop_requested.emit()

    def updated_credentials(self) -> None:
        """Called when the user clicks “Stop Engine”. """
        _QW_LOG.info("Sending updated credentials to Listener")
        
        new_credentials = {
            "a_user":  self.le_user_a.text(),
            "a_pass":  self.le_pass_a.text(),
            "b_user":  self.le_user_b.text(),
            "b_pass":  self.le_pass_b.text(),
            "c_user":  self.le_user_c.text(),
            "c_pass":  self.le_pass_c.text(),
        }
        self.listener_thread.signals.updated_credentials.emit(new_credentials)

    # Receive updates from the Listener when the Engine acts 
    @pyqtSlot(str)
    def update_performance_label(self, data: str) -> None:
        """Update the Performance:” label when the engine reports new data."""
        _QW_LOG.debug("Updated performance to {data}")
        self.lbl_performance.setText(f"{data}")

    @pyqtSlot()
    def on_engine_started(self) -> None:
        _QW_LOG.info("Engine reported STARTED (via signal)")
        self.btn_start.setEnabled(False)
        self.btn_stop.setEnabled(True)

    @pyqtSlot()
    def on_engine_stopped(self) -> None:
        _QW_LOG.info("Engine reported STOPPED (via signal)")
        self.btn_start.setEnabled(True)
        self.btn_stop.setEnabled(False)
        
    # ------------------------------------------------------------------
    # Slot that runs in the GUI thread and gathers the current field values
    # ------------------------------------------------------------------
    def _handle_credential_request(self, req_id: str):
        creds = {
            "a_user":  self.le_user_a.text(),
            "a_pass":  self.le_pass_a.text(),
            "b_user":  self.le_user_b.text(),
            "b_pass":  self.le_pass_b.text(),
            "c_user":  self.le_user_c.text(),
            "c_pass":  self.le_pass_c.text(),
        }
        # Emit the data back to the listener, tagging it with the same ID
        self.provideCredentials.emit({"id": req_id, "data": creds})

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