#!/usr/bin/env python3

import os
import sys
from pathlib import Path
from typing import Dict

from PyQt6.QtCore import Qt, QSize
from PyQt6.QtGui import QIcon
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QGridLayout,
    QComboBox,
    QStackedWidget,
    QTableWidget,
    QTableWidgetItem,
    QTextEdit, QPushButton
)
import re

# ----------------------------------------------------------------------
# Config helpers (unchanged)
# ----------------------------------------------------------------------
CONFIG_DIR = Path(os.getenv("APPDATA", "")) / "Qwertigraph"
CONFIG_FILE = CONFIG_DIR / "qw.config"

from dotenv import load_dotenv
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")          # <-- adjust path if needed

from log_factory import get_logger
_QW_LOG = get_logger("QW") 

def ensure_config_dir() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)


def load_config() -> Dict[str, str]:
    ensure_config_dir()
    cfg: Dict[str, str] = {}
    if not CONFIG_FILE.is_file():
        return cfg
    try:
        for line in CONFIG_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                cfg[k.strip()] = v.strip()
    except Exception as exc:
        print(f"⚠️  Could not read config: {exc}")
    return cfg


def save_config(values: Dict[str, str]) -> None:
    ensure_config_dir()
    lines = [f"{k} = {v}" for k, v in values.items()]
    try:
        CONFIG_FILE.write_text("\n".join(lines), encoding="utf-8")
    except Exception as exc:
        print(f"⚠️  Could not write config: {exc}")


# ----------------------------------------------------------------------
# Main window – now uses a ComboBox for navigation
# ----------------------------------------------------------------------
class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Qwertigraph – Engine Control")

        # Optional icon (same folder as script)
        icon_path = Path(__file__).with_name("coach.ico")
        if icon_path.is_file():
            self.setWindowIcon(QIcon(str(icon_path)))

        # ---------- Layout skeleton ----------
        central = QWidget(self)
        self.setCentralWidget(central)

        self.main_layout = QVBoxLayout(central)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.main_layout.setSpacing(0)

        # ----- Navigation combo box (right‑justified) -----
        nav_container = QWidget()
        nav_layout = QHBoxLayout(nav_container)
        nav_layout.setContentsMargins(5, 5, 5, 5)

        # Add a stretch first → pushes everything that follows to the right side
        nav_layout.addStretch()

        view_label = QLabel("View:")
        self.nav_combo = QComboBox()
        self.nav_combo.addItems(["Settings", "Editor", "Log", "Coach"])
        self.nav_combo.currentIndexChanged.connect(self._on_nav_changed)

        nav_layout.addWidget(view_label)
        nav_layout.addWidget(self.nav_combo)

        self.main_layout.addWidget(nav_container)

        # ----- Stacked pages (one visible at a time) -----
        self.stack = QStackedWidget()
        self.stack.addWidget(self._build_settings_page())  # index 0
        self.stack.addWidget(self._build_editor_page())    # index 1
        self.stack.addWidget(self._build_log_page())       # index 2
        self.stack.addWidget(self._build_coach_page())     # index 3
        self.main_layout.addWidget(self.stack)

        # ----- Bottom banner (always visible) -----
        banner = QWidget()
        banner.setObjectName("banner")
        banner_layout = QHBoxLayout(banner)
        banner_layout.setContentsMargins(5, 5, 5, 5)

        self.status_label = QLabel("Dashboard: ready")
        banner_layout.addWidget(self.status_label, alignment=Qt.AlignmentFlag.AlignLeft)

        self.main_layout.addWidget(banner)
        self.adjustSize() 
        
        # ---------- Sizing ----------
        screen = QApplication.primaryScreen()
        avail = screen.availableGeometry()
        self.base_height = avail.height() - 30
        self.base_width = 800
        self.coach_width = 180

        self.resize(self.base_width, self.base_height)
        self._pin_to_upper_right() 

        self.nav_combo.setCurrentIndex(3)
        self.stack.setCurrentIndex(3)
        
        self._scrubbing_regex = re.compile(r'\d')       

        _QW_LOG.info("UI initialized")
        ### Qwertigraph Engine Methods
        self.new_engine()
        
        _QW_LOG.info("Started Engine in startup")

    # ------------------------------------------------------------------
    # Page builders (identical to the tab version, just renamed)
    # ------------------------------------------------------------------
    def _build_settings_page(self) -> QWidget:
        widget = QWidget()
        self.setting_fields: Dict[str, QLineEdit] = {}

        # Credential input fields
        settings_grid = QGridLayout(widget)
        settings_grid.setHorizontalSpacing(5)
        settings_grid.setVerticalSpacing(5)
        
        # Control buttons
        self.btn_start = QPushButton("Start Engine", self)
        self.btn_start.clicked.connect(self.start_engine)
        settings_grid.addWidget(self.btn_start, 0, 1)

        self.btn_stop = QPushButton("Stop Engine", self)
        self.btn_stop.clicked.connect(self.stop_engine)
        settings_grid.addWidget(self.btn_stop, 1, 1)

        # Credentials 
        # Row 0 – Credential A
        settings_grid.addWidget(QLabel("Credential A:", self), 2, 0)
        self.user_a = QLineEdit(self)          # username field
        settings_grid.addWidget(self.user_a, 2, 1)
        self.setting_fields['user_a'] = self.user_a
        self.pass_a = QLineEdit(self)          # password field
        self.pass_a.setEchoMode(QLineEdit.EchoMode.Password)
        settings_grid.addWidget(self.pass_a, 3, 1)

        # Row 1 – Credential B
        settings_grid.addWidget(QLabel("Credential B:", self), 4, 0)
        self.user_b = QLineEdit(self)
        settings_grid.addWidget(self.user_b, 4, 1)
        self.setting_fields['user_b'] = self.user_b
        self.pass_b = QLineEdit(self)
        self.pass_b.setEchoMode(QLineEdit.EchoMode.Password)
        settings_grid.addWidget(self.pass_b, 5, 1)

        # Row 2 – Credential C
        settings_grid.addWidget(QLabel("Credential C:", self), 6, 0)
        self.user_c = QLineEdit(self)
        settings_grid.addWidget(self.user_c, 6, 1)
        self.setting_fields['user_c'] = self.user_c
        self.pass_c = QLineEdit(self)
        self.pass_c.setEchoMode(QLineEdit.EchoMode.Password)
        settings_grid.addWidget(self.pass_c, 7, 1)


        self.btn_credentials = QPushButton("Update Creds", self)
        self.btn_credentials.clicked.connect(self.updated_credentials)
        settings_grid.addWidget(self.btn_credentials, 8, 1)

        cfg = load_config()
        for key, edit in self.setting_fields.items():
            if key in cfg:
                edit.setText(cfg[key])

        for edit in self.setting_fields.values():
            edit.editingFinished.connect(self._save_settings)
        return widget

    def _save_settings(self) -> None:
        # Keep only keys that do NOT start with the forbidden prefix
        values = {
            k: w.text()
            for k, w in self.setting_fields.items()
            if not k.startswith("pass_")
        }

        save_config(values)                     # writes the filtered dict
        self.status_label.setText("Dashboard: settings saved")

    def _build_editor_page(self) -> QWidget:
        widget = QWidget()
        layout = QVBoxLayout(widget)

        table = QTableWidget(8, 20)
        table.setHorizontalHeaderLabels([str(i) for i in range(1, 21)])
        table.setVerticalHeaderLabels([str(i) for i in range(1, 9)])
        layout.addWidget(table)

        self.editor_table = table
        return widget

    def _build_log_page(self) -> QWidget:
        widget = QWidget()
        layout = QVBoxLayout(widget)

        log_area = QTextEdit()
        log_area.setReadOnly(True)
        layout.addWidget(log_area)

        self.log_area = log_area
        return widget

    def _build_coach_page(self) -> QWidget:
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(0, 0, 0, 0)   # no extra margins
        layout.setSpacing(0)                   # panes touch each other

        self.upper = QTextEdit(self)
        self._configure_text_edit(self.upper)
        layout.addWidget(self.upper)
        self.lower = QTextEdit(self)
        self._configure_text_edit(self.lower)
        layout.addWidget(self.lower)

        return widget
    
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
    # Navigation handling
    # ------------------------------------------------------------------
    def _on_nav_changed(self, idx: int) -> None:
        """
        Called when the combo box selection changes.
        * Switches the stacked widget page.
        * Resizes the window (800 px ↔ 180 px) depending on the page.
        * Updates the dashboard label.
        """
        self.stack.setCurrentIndex(idx)

        if idx == 3:                     # Coach page
            self.resize(self.coach_width, self.base_height)
            self.status_label.setText("Dashboard: Coach mode")
        else:
            self.resize(self.base_width, self.base_height)
            page_name = self.nav_combo.itemText(idx)
            self.status_label.setText(f"Dashboard: {page_name}")

        # Keep the window glued to the upper‑right corner after a resize
        self._pin_to_upper_right()

    # ------------------------------------------------------------------
    # Optional helper – keep window in the upper‑right corner
    # ------------------------------------------------------------------
    def _pin_to_upper_right(self) -> None:
        geom = QApplication.primaryScreen().availableGeometry()
        x = geom.x() + geom.width() - self.width()
        y = geom.y()
        self.move(x, y)

    # ------------------------------------------------------------------
    # Public method to append log entries (used by demo timer)
    # ------------------------------------------------------------------
    def append_log(self, msg: str) -> None:
        self.log_area.append(msg)

    def resizeEvent(self, event) -> None:
        super().resizeEvent(event)
        self._pin_to_upper_right()

    # ------------------------------------------------------------------
    # Qwertigraph Engine Methods 
    # ------------------------------------------------------------------
    def new_engine(self) -> None:
        _QW_LOG.info("Building new Engine")
        
        
        from comms_proxy import Comms_Proxy
        from key_input import Key_Input        
        from key_output import Key_Output
        from engine import Expansion_Engine
        from scribe import Scribe
        from key_queue import Key_Queue

        self._comms_proxy = Comms_Proxy(ui=self)
        self._scribe = Scribe(self._comms_proxy)
        self._key_output = Key_Output(self._scribe)
        self._engine = Expansion_Engine(self._key_output, self._comms_proxy)
        self._key_queue = Key_Queue(self._engine)  
        self._key_input = Key_Input(self._key_queue, self._comms_proxy)
        self._comms_proxy.set_key_input(self._key_input)
        self._key_input.start_listening()
        _QW_LOG.info("Built new Engine")
 
    def set_coach_upper(self, text: str):
        # print(f"Setting upper text to: {text}")
        scrubbed_text = self._scrub_text(text)
        self.upper.setPlainText(scrubbed_text)
        self.upper.verticalScrollBar().setValue(self.upper.verticalScrollBar().maximum())

    def set_coach_lower(self, text: str):
        # print(f"Setting lower text to: {text} for self {self}")
        # print(f"lower is {self.lower}")
        scrubbed_text = self._scrub_text(text)
        # print(f"Setting lower text to scrubbed: {scrubbed_text}")
        self.lower.setPlainText(scrubbed_text)
        # print(f"Setting scrollbar") 
        self.lower.verticalScrollBar().setValue(self.lower.verticalScrollBar().minimum())

    def append_coach_upper(self, line: str):
        # print(f"Appending to upper text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.upper.append(scrubbed_line)
        self.upper.verticalScrollBar().setValue(self.upper.verticalScrollBar().maximum())

    def append_coach_lower(self, line: str):
        # print(f"Appending to lower text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.lower.append(scrubbed_line)
        self.lower.verticalScrollBar().setValue(self.lower.verticalScrollBar().minimum())

    def _scrub_line(self, line: str):
        # print(f"Scrubbing: {line}")
        if re.search(self._scrubbing_regex, line):
            # print(f"matched: {line}")
            return '****'
        else:
            # print(f"ignored: {line}")
            return line

    def _scrub_text(self, text: str):
        if re.search(self._scrubbing_regex, text):
            # print(f"matched: {text}")
            return '****'
        else:
            # print(f"ignored: {text}")
            return text


    def update_performance(self, line: str):
        # print(f"Performance is: {line}")
        self.status_label.setText(line)

    def start_engine(self):
        _QW_LOG.info("Starting engine")  
        self._comms_proxy.signal_engine_start()         
        pass

    def stop_engine(self):
        _QW_LOG.info("Stopping engine") 
        self._comms_proxy.signal_engine_stop()       
        pass 

    def on_engine_started(self):
        _QW_LOG.info("Notified engine started")
        self.btn_start.setEnabled(False)
        self.btn_stop.setEnabled(True)


    def on_engine_stopped(self):
        _QW_LOG.info("Notified engine stopped")
        self.btn_start.setEnabled(True)
        self.btn_stop.setEnabled(False)

    def updated_credentials(self):
        _QW_LOG.info("Sending updated credentials to Listener")
        
        new_credentials = {
            "a_user":  self.user_a.text(),
            "a_pass":  self.pass_a.text(),
            "b_user":  self.user_b.text(),
            "b_pass":  self.pass_b.text(),
            "c_user":  self.user_c.text(),
            "c_pass":  self.pass_c.text(),
        }

        self._comms_proxy.signal_vaulter_new_credentials(new_credentials)



# ----------------------------------------------------------------------
# Application entry point
# ----------------------------------------------------------------------
def main() -> None:
    app = QApplication(sys.argv)

    # Light style for the banner (optional)
    app.setStyleSheet(
        """
        /* All widgets inherit a white background */
        QWidget {
            background-color: white;
        }

        /* Keep the banner a subtle gray so it still stands out */
        #banner {
            background-color: #f0f0f0;
            border-top: 1px solid #c0c0c0;
        }
        """
    )

    win = MainWindow()
    win.show()

    # Demo: periodic log messages (remove in production)
    from PyQt6.QtCore import QTimer

    counter = 0

    def demo_log():
        nonlocal counter
        counter += 1
        win.append_log(f"Demo log entry #{counter}")

    timer = QTimer()
    timer.timeout.connect(demo_log)
    timer.start(3000)  # every 3 seconds

    sys.exit(app.exec())


if __name__ == "__main__":
    main()