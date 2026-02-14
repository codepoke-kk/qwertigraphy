#!/usr/bin/env python3

import os
import sys
from pathlib import Path, PurePath
from typing import Dict, List, Any
import json 
from datetime import datetime

from PyQt6.QtCore import Qt, QSize, QSortFilterProxyModel, QModelIndex
from PyQt6.QtGui import QIcon, QStandardItemModel, QStandardItem
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QGridLayout, QComboBox, QStackedWidget, QTableWidget, QTableWidgetItem,
    QTextEdit, QPushButton, QListWidget, QInputDialog, QMessageBox, QSizePolicy,
    QTableView, QHeaderView
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

from dictionary import Entry, Source_Dictionary, Composite_Dictionary
from inflector import Inflector
from gregg_dict import Gregg_Dict
from entry_helper import Entry_Helper

def ensure_config_dir() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

def load_config() -> Dict[str, Any]:
    """
    Load the JSON configuration file and return a dict.
    If the file does not exist or cannot be parsed, an empty dict is returned.
    """
    ensure_config_dir()
    _QW_LOG.debug("Loading config")

    if not CONFIG_FILE.is_file():
        _QW_LOG.debug("Config file missing – returning empty dict")
        return {}

    try:
        data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            _QW_LOG.warning("Config file did not contain a JSON object – resetting")
            return {}
        
        # Make sure we have some dictionaries. 
        if "dict_sources" not in data or not isinstance(data["dict_sources"], list) or not (len(data["dict_sources"])):
            data["dict_sources"] = [
                "%AppData%/Qwertigraph/personal.csv",
                "dictionaries/anniversary_required.csv",
                "dictionaries/anniversary_uniform_supplement.csv",
                "dictionaries/anniversary_uniform_core.csv",
                "dictionaries/anniversary_modern.csv",
                "dictionaries/anniversary_cmu.csv"
            ]
        
        _QW_LOG.debug(f"Config loaded: keys={list(data.keys())}")
        return data
    except Exception as exc:            # pragma: no cover – defensive logging
        print(f"⚠️  Could not read config: {exc}")
        return {}

def save_config(values: Dict[str, Any]) -> None:
    ensure_config_dir()
    tmp_path = CONFIG_FILE.with_suffix(".tmp")

    try:
        # `indent=2` makes the file nicely readable for humans.
        tmp_path.write_text(json.dumps(values, indent=2, sort_keys=True), encoding="utf-8")
        tmp_path.replace(CONFIG_FILE)   # atomic replace on most OSes
        _QW_LOG.debug(f"Configuration saved to {CONFIG_FILE}")
    except Exception as exc:            # pragma: no cover – defensive logging
        print(f"⚠️  Could not write config: {exc}")


# ----------------------------------------------------------------------
# Main window – now uses a ComboBox for navigation
# ----------------------------------------------------------------------
class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()

        self.inflector = Inflector()
        self.gregg_dict = Gregg_Dict()

        self.setWindowTitle("Qwertigraph – Engine Control")
        self.base_width = 1200
        self.coach_hints_width = 180

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

        banner_layout.addStretch()
        self.status_label = QLabel("Dashboard: ready")
        banner_layout.addWidget(self.status_label, alignment=Qt.AlignmentFlag.AlignLeft)

        self.main_layout.addWidget(banner)
        self.adjustSize() 
        
        # ---------- Sizing ----------
        screen = QApplication.primaryScreen()
        avail = screen.availableGeometry()
        self.base_height = avail.height() - 30

        self.resize(self.base_width, self.base_height)
        self._pin_to_upper_right() 

        self.nav_combo.setCurrentIndex(3)
        self.stack.setCurrentIndex(3)
        
        self._scrubbing_regex = re.compile(r'\d')       

        _QW_LOG.info("UI initialized")
        ### Qwertigraph Engine Methods
        self.new_engine()
        self.entry_helper = Entry_Helper(self, self.composite)
        
        _QW_LOG.info("Started Engine in startup")

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

        # ------------------- NEW: Dictionary Sources ------------------
        # Label
        settings_grid.addWidget(QLabel("Dictionary Sources:", self), 9, 0)

        # List widget (holds the array of strings)
        self.dict_source_list = QListWidget(self)
        self.dict_source_list.setSelectionMode(
            QListWidget.SelectionMode.MultiSelection
        )
        settings_grid.addWidget(self.dict_source_list, 9, 1)

        # --------------------------------------------------------------
        # Create a *single* vertical layout that holds all three buttons
        # --------------------------------------------------------------
        btn_vbox = QVBoxLayout()
        btn_vbox.setSpacing(4)

        btn_add_src = QPushButton("Add Source", self)
        btn_add_src.clicked.connect(self._add_dict_source)
        btn_vbox.addWidget(btn_add_src)

        btn_remove_src = QPushButton("Remove Selected", self)
        btn_remove_src.clicked.connect(self._remove_selected_sources)
        btn_vbox.addWidget(btn_remove_src)

        btn_move_up = QPushButton("▲ Move Up", self)
        btn_move_up.clicked.connect(self._move_up_selected)
        btn_vbox.addWidget(btn_move_up)

        btn_move_down = QPushButton("▼ Move Down", self)
        btn_move_down.clicked.connect(self._move_down_selected)
        btn_vbox.addWidget(btn_move_down)

        # Wrap the layout in a dummy widget so we can add it to the grid
        btn_holder = QWidget(self)
        btn_holder.setLayout(btn_vbox)

        # Place the button column *below* the list (still column 1)
        settings_grid.addWidget(btn_holder, 9, 2)   # row 10, same column as the list

        cfg = load_config()
        for key, edit in self.setting_fields.items():
            if key in cfg:
                edit.setText(cfg[key])

        # Populate the dictionary‑source list
        if "dict_sources" in cfg and isinstance(cfg["dict_sources"], list):
            for src in cfg["dict_sources"]:
                self.dict_source_list.addItem(str(src))

        for edit in self.setting_fields.values():
            edit.editingFinished.connect(self._save_settings)

        # Also save when the list widget changes (add/remove)
        self.dict_source_list.itemChanged.connect(self._save_settings)

        return widget

    def _add_dict_source(self) -> None:
        """Prompt the user for a new source and append it to the list."""
        text, ok = QInputDialog.getText(
            self,
            "Add Dictionary Source",
            "Enter the source URL or identifier:",
        )
        if ok and text.strip():
            # Avoid duplicate entries (optional)
            existing = [
                self.dict_source_list.item(i).text()
                for i in range(self.dict_source_list.count())
            ]
            if text in existing:
                QMessageBox.information(
                    self,
                    "Duplicate",
                    "That source is already in the list.",
                )
                return
            self.dict_source_list.addItem(text.strip())
            self._save_settings()

    def _remove_selected_sources(self) -> None:
        """Delete every selected item from the list."""
        for item in self.dict_source_list.selectedItems():
            self.dict_source_list.takeItem(self.dict_source_list.row(item))
        self._save_settings()

    def _move_up_selected(self) -> None:
        """
        Move the currently selected row(s) one position upward.
        If multiple rows are selected, they retain their relative order.
        """
        selected_items = self.dict_source_list.selectedItems()
        if not selected_items:
            return

        # Process items in the order they appear in the list (top-to-bottom)
        for item in selected_items:
            row = self.dict_source_list.row(item)
            if row == 0:                 # already at top – nothing to do
                continue

            # Take the item out, then insert it one row higher
            taken_item = self.dict_source_list.takeItem(row)
            self.dict_source_list.insertItem(row - 1, taken_item)
            taken_item.setSelected(True)   # keep it selected

        self._save_settings()              # persist the new order


    def _move_down_selected(self) -> None:
        """
        Move the currently selected row(s) one position downward.
        If multiple rows are selected, they retain their relative order.
        """
        selected_items = self.dict_source_list.selectedItems()
        if not selected_items:
            return

        # Important: when moving down we must iterate **bottom-to-top**
        # so that earlier inserts don’t shift the indices of items we
        # haven’t processed yet.
        for item in reversed(selected_items):
            row = self.dict_source_list.row(item)
            if row == self.dict_source_list.count() - 1:   # already last
                continue

            taken_item = self.dict_source_list.takeItem(row)
            self.dict_source_list.insertItem(row + 1, taken_item)
            taken_item.setSelected(True)

        self._save_settings()

    def _save_settings(self) -> None:
        """
        Collect all UI values and write them back to the config file.
        This method is called whenever a line‑edit loses focus or the
        source list is modified.
        """
        cfg: Dict[str, object] = {}

        # --- credentials (simple strings) ---
        for key, edit in self.setting_fields.items():
            cfg[key] = edit.text()

        # --- dictionary sources (array) ---
        sources: List[str] = [
            self.dict_source_list.item(i).text()
            for i in range(self.dict_source_list.count())
        ]
        cfg["dict_sources"] = sources

        # Write the file – replace this with your actual persistence logic
        save_config(cfg)   # <-- you already have a `save_config` helper somewhere

        # Reload the dictionaries based on the new config 
        self.load_composite_dictionary()
        self.append_log(f"Updated settings saved")


    def _build_editor_page(self) -> QWidget:
        _QW_LOG.info("Building Editor")
        self.EDITOR_COLUMN_COUNT = 7
        self.EDITOR_HEADER_LABELS = [
            "Word",
            "Form",
            "Qwerd",
            "Keyer",
            "Chord",
            "Usage",
            "Source",   # 7th column – identifies the source dictionary
        ]
        self.editor_base_model = QStandardItemModel(0, self.EDITOR_COLUMN_COUNT, self)
        self.editor_base_model.setHorizontalHeaderLabels(self.EDITOR_HEADER_LABELS)
        self.editor_proxy = QSortFilterProxyModel(self)
        self.editor_proxy.setSourceModel(self.editor_base_model)
        self.editor_proxy.setFilterKeyColumn(-1)   # we filter manually per column

        self.load_composite_dictionary()

        widget = QWidget()
        
        main_layout = QVBoxLayout(widget)

        # ---------- 1️⃣ Filter bar ----------
        self.filter_edits: List[QLineEdit] = []
        filter_bar = QHBoxLayout()
        for col in range(self.EDITOR_COLUMN_COUNT):
            le = QLineEdit(self)
            le.setPlaceholderText(f"filter {col + 1}")
            le.textChanged.connect(self._apply_filters)
            self.filter_edits.append(le)
            filter_bar.addWidget(le)
        main_layout.addLayout(filter_bar)

        # ---------- 2️⃣ Central area (table + edit fields) ----------
        central_hbox = QHBoxLayout()
        main_layout.addLayout(central_hbox)

        # ----- Left pane : table + edit fields -----
        left_vbox = QVBoxLayout()
        central_hbox.addLayout(left_vbox, stretch=1)

        # ----- Table view (filtered) -----
        self.table_view = QTableView(self)
        self.table_view.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)
        self.table_view.setModel(self.editor_proxy) 
        self.table_view.doubleClicked.connect(self._load_row_into_editors)
        left_vbox.addWidget(self.table_view)

        # ----- Edit bar (7 fields) -----
        edit_bar = QHBoxLayout()
        self.editor_edits: List[QLineEdit] = []
        for col in range(self.EDITOR_COLUMN_COUNT - 1):          # first 6 are plain QLineEdit
            le = QLineEdit(self)
            le.setPlaceholderText(f"col {col + 1}")
            self.editor_edits.append(le)
            edit_bar.addWidget(le)

        # 7th field is a combo‑box that selects the source dictionary
        self.source_combo = QComboBox(self)
        edit_bar.addWidget(self.source_combo)

        # Add / Update button
        self.btn_add_update = QPushButton("Add / Update", self)
        self.btn_add_update.clicked.connect(self._add_or_update_from_edit_fields)
        edit_bar.addWidget(self.btn_add_update)

        left_vbox.addLayout(edit_bar)

        # ----- Right pane : rapid‑creation buttons -----
        right_vbox = QVBoxLayout()
        central_hbox.addLayout(right_vbox)

        btn = QPushButton('DELETE', self)
        btn.clicked.connect(lambda _, n='DELETE': self._delete_button_clicked(n))
        right_vbox.addWidget(btn)

        # Placeholder button names (feel free to extend)
        button_names = ["S", "D", "G", "ER", "OR", "LY", "ALLY", "ION", "ATION", "ABLE", "ABILITY", "FUL", "NESS", "MENT"]
        for name in button_names:
            btn = QPushButton(name, self)
            btn.clicked.connect(lambda _, n=name: self._rapid_button_clicked(n))
            right_vbox.addWidget(btn)

        right_vbox.addStretch()   # push buttons to the top

        # ---------- 3️⃣ Bottom bar (Save) ----------
        bottom_bar = QHBoxLayout()
        self.btn_gregg_dict_lookup = QPushButton("Display Gregg Form", self)
        self.btn_gregg_dict_lookup.clicked.connect(self._gregg_dict_lookup_action)
        bottom_bar.addWidget(self.btn_gregg_dict_lookup)
        self.btn_entry_helper = QPushButton("Define Entry from Form", self)
        self.btn_entry_helper.clicked.connect(self._entry_helper_autofill)
        bottom_bar.addWidget(self.btn_entry_helper)
        bottom_bar.addStretch()
        self.btn_save_all = QPushButton("Save All Dictionaries", self)
        self.btn_save_all.clicked.connect(self._save_all_sources)
        bottom_bar.addWidget(self.btn_save_all)
        main_layout.addLayout(bottom_bar)

        # Make columns stretch to fill the view
        header = self.table_view.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.ResizeMode.Stretch)

        self._populate_ui_from_composite()

        return widget

    def _populate_ui_from_composite(self) -> None:
        """Load all entries and source names into the UI."""
        # Fill the source combo box
        self.source_combo.clear()
        for src_name in self.composite.get_source_names():
            self.source_combo.addItem(src_name)

        # Load every entry into the base model
        self.editor_base_model.removeRows(0, self.editor_base_model.rowCount())
        for entry in self.composite.all_entries():          # entry is List[str] length 7
            items = [QStandardItem(str(cell)) for cell in entry]
            self.editor_base_model.appendRow(items)


    def _apply_filters(self):
        patterns = [
            (col, edit.text().strip().lower())
            for col, edit in enumerate(self.filter_edits)
            if edit.text().strip()
        ]

        for row in range(self.editor_base_model.rowCount()):
            match = True
            for col, pat in patterns:
                cell_text = self.editor_base_model.item(row, col).text().lower()
                if pat not in cell_text:
                    match = False
                    break
            self.table_view.setRowHidden(row, not match)

    def _load_row_into_editors(self, proxy_index: QModelIndex) -> None:
        src_index = self.editor_proxy.mapToSource(proxy_index)
        row = src_index.row()

        # Populate the six plain editors
        for col in range(self.EDITOR_COLUMN_COUNT - 1):
            txt = self.editor_base_model.item(row, col).text()
            self.editor_edits[col].setText(txt)

        # Populate the source combo
        src_name = self.editor_base_model.item(row, self.EDITOR_COLUMN_COUNT - 1).text()
        if src_name == 'anniversary_uniform_core.csv':
            src_name = 'anniversary_uniform_supplement.csv'
        idx = self.source_combo.findText(src_name)
        if idx != -1:
            self.source_combo.setCurrentIndex(idx)

        # Store the *original* row data so we can perform an update later
        self._currently_loaded_row = [self.editor_base_model.item(row, c).text()
                                      for c in range(self.EDITOR_COLUMN_COUNT)]

    def _load_entry_into_editors(self, entry: Entry) -> None:

        self.editor_edits[0].setText(entry.word)
        self.editor_edits[1].setText(entry.form)
        self.editor_edits[2].setText(entry.qwerd)
        self.editor_edits[3].setText(entry.keyer)
        self.editor_edits[4].setText(entry.chord)
        self.editor_edits[5].setText(entry.usage)

        # Populate the source combo
        src_name = entry.source 
        idx = self.source_combo.findText(src_name)
        if idx != -1:
            self.source_combo.setCurrentIndex(idx)

        # Reset the *original* row data so we can perform an update later
        self._currently_loaded_row = None 
        
    def _add_or_update_from_edit_fields(self) -> None:
        # Gather the 7 values from the UI
        new_values = [le.text() for le in self.editor_edits]
        src_name = self.source_combo.currentText()
        if not src_name:
            QMessageBox.warning(self, "Missing source",
                                "Select a source dictionary in the last field.")
            return
        new_values.append(src_name)          # column 7 = source name
        self._add_or_update_to_base_model(new_values)

    def _add_or_update_from_entry(self, entry: Entry) -> None:
        new_values = [
            entry.word,
            entry.form,
            entry.qwerd,
            entry.keyer,
            entry.chord,
            entry.usage,
            entry.source
        ]
        self._add_or_update_to_base_model(new_values)

    def _add_or_update_to_base_model(self, new_values) -> None:
        
        qwerd_to_match = new_values[2]  

        row_to_update = -1                                            # sentinel
        for r in range(self.editor_base_model.rowCount()):
            # Grab the qwerd of the current row (column 2)
            existing_qwerd = self.editor_base_model.item(r, 2).text()
            if existing_qwerd == qwerd_to_match:
                row_to_update = r
                break                                                # stop at first match (qwerd is unique)

        if row_to_update != -1:
            # ----- UPDATE -----
            for c, val in enumerate(new_values):
                # ``item`` is guaranteed to exist because the model already has this row
                self.editor_base_model.item(row_to_update, c).setText(val)
        else:
            # ----- ADD -----
            items = [QStandardItem(v) for v in new_values]
            self.editor_base_model.appendRow(items)

        entry = Entry(*new_values)
        self.composite.put(entry)
        _QW_LOG.debug(f"Put entry {entry} to composite dictionary")
        self._engine.put_expansions(entry.qwerd, entry.word)
        _QW_LOG.debug(f"Put entry {entry} to engine expansions")

        # Re‑apply filters so a newly added row appears/disappears correctly
        self._apply_filters()
        self.append_log(f"Put entry {entry} to composite dictionary and engine expansions")

    def _delete_button_clicked(self, button_name) -> None:
        _QW_LOG.debug(f"{button_name} clicked")
        sel_model = self.table_view.selectionModel()
        # Sort in reverse order so deleting rows doesn’t mess up indices
        rows_via_selectedIndexes = sorted({idx.row() for idx in sel_model.selectedIndexes()}, reverse=True)
        _QW_LOG.debug(f"sorted selectedIndexes(): {rows_via_selectedIndexes}")

        # Populate the six plain editors
        if len(rows_via_selectedIndexes) == 0:
            QMessageBox.warning(self, "No selection",
                                "Select a row to delete.")
            return

        for row in rows_via_selectedIndexes:
            base_values = []
            for col in range(self.EDITOR_COLUMN_COUNT):
                txt = self.editor_base_model.item(row, col).text()
                base_values.append(txt)
            _QW_LOG.debug("Base values are: " + str(base_values))

            entry = Entry(*base_values)

            # Need to modify 1) Base Model, 2) Composite Dictionary, 3) Engine Expansions
            self.editor_base_model.removeRow(row)
            _QW_LOG.debug(f"Deleted row {row}")
            self.composite.delete(entry.qwerd)
            _QW_LOG.debug(f"Deleted entry {entry} from composite dictionary")
            self._engine.delete_expansions(entry.qwerd)
            _QW_LOG.debug(f"Deleted entry {entry} from engine expansions")


        # Re‑apply filters so a newly added row appears/disappears correctly
        self._apply_filters()
        # Reload the expansions into the Engine 
        # self._engine.load_expansions()
        self.append_log(f"Removed entry {entry} from composite dictionary and engine expansions")
        
    def _rapid_button_clicked(self, button_name) -> None:
        """
        Do a full create of a new entry with sent values
        """
        # Gather the 7 values from the UI
        _QW_LOG.debug(f"Adding rapid entry for button {button_name}")
        sel_model = self.table_view.selectionModel()
        rows_via_selectedIndexes = sorted({idx.row() for idx in sel_model.selectedIndexes()})
        _QW_LOG.debug(f"sorted selectedIndexes(): {rows_via_selectedIndexes}")
        
        # Fail if no selection 
        if len(rows_via_selectedIndexes) == 0:
            QMessageBox.warning(self, "No selection",
                                "Select a row to copy base values from.")
            return
        
        for row in rows_via_selectedIndexes:
            # Get values from the selected row 
            base_values = []
            for col in range(self.EDITOR_COLUMN_COUNT):
                txt = self.editor_base_model.item(row, col).text()
                base_values.append(txt)
            _QW_LOG.debug("Base values are: " + str(base_values))

            # Build them into an entry 
            source_entry = Entry(*base_values)
            _QW_LOG.debug("Entry is: " + str(source_entry))

            # Inflect the entry based on the button name
            entry = self.inflector.inflect(source_entry, button_name)
            _QW_LOG.debug("Inflected entry is: " + str(entry))

            # Look for a collision 
            collision_entry = self.composite.read(entry.qwerd)
            if collision_entry:
                self._load_entry_into_editors(collision_entry)
            else:
                # Erase editors         
                self.editor_edits[0].setText('')
                self.editor_edits[1].setText('')
                self.editor_edits[2].setText('')
                self.editor_edits[3].setText('')
                self.editor_edits[4].setText('')
                self.editor_edits[5].setText('')
                self.source_combo.setCurrentIndex(0)
            
            # Need to modify 1) Base Model, 2) Composite Dictionary, 3) Engine Expansions
            # items = [QStandardItem(v) for v in entry.get_items_list()]
            # self.editor_base_model.appendRow(items)
            self._add_or_update_from_entry(entry)
            _QW_LOG.debug(f"Appended row {row}")
            self.composite.put(entry)
            _QW_LOG.debug(f"Put entry {entry} to composite dictionary")
            self._engine.put_expansions(entry.qwerd, entry.word)
            _QW_LOG.debug(f"Put entry {entry} to engine expansions")


        # Re‑apply filters so a newly added row appears/disappears correctly
        self._apply_filters()
        self.append_log(f"Put entry {entry} to composite dictionary and engine expansions")

    def get_last_unbracketed_word(self) -> str | None:
        # Find the word to lookup from the hints 
        raw_text: str = self.upper_tape.toPlainText()
        raw_text = raw_text.replace("\r\n", "\n")

        # Apply the pattern.  ``^`` anchors to the start of the line,
        #    ``\w+`` captures the word, and we require a space or end‑of‑line
        #    after it (the look‑ahead ``(?= |\Z)``).
        pattern = re.compile(r"^(?P<word>\w+)(?= |\Z)")
        lines = raw_text.split("\n")
        for line in reversed(lines):
            line = line.rstrip()
            match = pattern.search(line)
            if match:
                # Found the first (i.e. *last* in the whole document) word.
                return match.group("word")

        return None
    
    def focus_tab(self, tab, focus: str = '') -> None: 
        _QW_LOG.debug(f"Focusing the {tab} tab")
        self.append_log(f"Focusing the {tab} tab")
        self.switch_to_tab(tab)
        if focus == 'foreground':
            self.raise_()
            self.activateWindow()
    
    def focus_coach(self) -> None: 
        _QW_LOG.debug("Focusing the Coach")
        self.switch_to_tab("Coach")
    
    def gregg_dict_lookup_word(self, mode: str = 'Active') -> None: 
        _QW_LOG.debug("Gregg_Dict lookup")
        self.raise_()          # moves the window to the top of the sticking order
        self.activateWindow() # gives it keyboard focus
        word = self.get_last_unbracketed_word()
        if not word:
            word = 'No words found'
        self.switch_to_tab("Editor")
        self.filter_edits[0].setText(word.capitalize())
        self.editor_edits[0].setText(word.capitalize())
        if mode == 'Active':
            self._gregg_dict_lookup(word.capitalize())
        
    def _gregg_dict_lookup_action(self) -> None:
        word = self.editor_edits[0].text().strip()
        if not word:
            QMessageBox.warning(self, "No word",
                                "Enter a shorthand word to look up in the Gregg Dictionary")
            return  
        self._gregg_dict_lookup(word)

    def _gregg_dict_lookup(self, word: str) -> None:
        _QW_LOG.debug(f"Performing lookup by Gregg_Dict for word: {word}")
        self.append_log(f"Performing lookup by Gregg_Dict for word: {word}")
        result = self.gregg_dict.find_best_match(word)

        while word:    # Loop while there is still at least one char
            _QW_LOG.debug(f"Performing lookup by Gregg_Dict for word: '{word}'")
            result = self.gregg_dict.find_best_match(word)

            # If the result is truthy (e.g., a non‑empty list/dict/string), we’re done
            if result:
                break

            # No match – drop the last character and try again
            word = word[:-1]

        if result:
            page, word, x, y = result
            _QW_LOG.debug(f'Query "{word}" → page {page}, word "{word}", coordinates ({x}, {y})')
            url = self.gregg_dict.build_local_url_query(page, x, y, word, transformed=True)
            _QW_LOG.debug(f'Opening → {url}')          # optional: lets you see what is opened
            self.gregg_dict.open_via_shell(url) 
        else:
            QMessageBox.warning(self, "No match",
                                f"No match for '{word}' in the Gregg Dictionary")
            return
        
    def _entry_helper_autofill(self) -> None:
        word = self.editor_edits[0].text().strip()
        form = self.editor_edits[1].text().strip()   # second field = form
        if not word or not form:
            QMessageBox.warning(self, "No word or form",
                                "Enter a shorthand word and form to autofill remaining fields")
            return
        _QW_LOG.debug(f"Performing entry helper autofill for word/form: {word}/{form}")
        self.append_log(f"Performing entry helper autofill for word/form: {word}/{form}")
        qwerd, keyer = self.entry_helper.qwerd_and_keyer_from_word_and_form(word, form)
        if not qwerd:
            _QW_LOG.debug(f"Autofill was cancelled or failed")
            return 
        self.editor_edits[2].setText(qwerd)
        self.editor_edits[3].setText(keyer)
        self.editor_edits[4].setText(f"q{''.join(sorted(set(qwerd.lower())))}")
        _QW_LOG.debug(f"Autofilled Qwerd: {qwerd} and {keyer}")
         
    def _save_all_sources(self) -> None:
        self.composite.save_all()
        self.switch_to_tab("Coach")
        # QMessageBox.information(self, "Saved",
        #                         "All dictionaries have been saved successfully.")
        
    def load_composite_dictionary(self):
        from dictionary import Entry, Source_Dictionary, Composite_Dictionary
        # src1 = Source_Dictionary(name="anniversary_uniform_core.csv", csv_path="dictionaries/anniversary_uniform_core.csv")
        # src2 = Source_Dictionary(name="anniversary_uniform_supplement.csv", csv_path="dictionaries/anniversary_uniform_supplement.csv")

        # --- dictionary sources (array) ---
        sources = []
        csv_paths = []
        for i in range(self.dict_source_list.count()):
            csv_path = self.dict_source_list.item(i).text()
            csv_paths.append(csv_path)
            name = os.path.basename(PurePath(csv_path).as_posix())
            source = Source_Dictionary(name=name, csv_path=csv_path)
            sources.append(source)
        self.composite = Composite_Dictionary(sources)
        os.environ['DICTIONARY_PATHS'] = ','.join(csv_paths)
        _QW_LOG.info(f"Dictionary loaded of {len(self.composite.all_entries())} entries")
        # self.append_log(f"Dictionary loaded of {len(self.composite.all_entries())} entries")

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
        v_layout = QVBoxLayout(widget)
        v_layout.setContentsMargins(0, 0, 0, 0)
        v_layout.setSpacing(0)

        # ---------------- Upper pane ----------------
        self.upper_tape = QTextEdit(self)
        self.upper_tape.setText("Hint log")
        self.upper_hints = QTextEdit(self)
        self.upper_hints.setText("Missed words")

        upper_pane = self._make_three_column_pane(
            tape_edit=self.upper_tape,
            hint_edit=self.upper_hints,
            top_btn_text="Analyze",
            top_btn_slot=self.analyze_hints,
            bottom_btn_text="Lookup",
            bottom_btn_slot=self.lookup_from_hints,
            hint_fixed_width=220,          # adjust to whatever width you like
        )
        v_layout.addWidget(upper_pane)

        # ---------------- Lower pane ----------------
        self.lower_tape = QTextEdit(self)
        self.lower_tape.setText("Predictive words")
        self.lower_hints = QTextEdit(self)
        self.lower_hints.setText("Opportunity words")

        lower_pane = self._make_three_column_pane(
            tape_edit=self.lower_tape,
            hint_edit=self.lower_hints,
            top_btn_text="Analyze",
            top_btn_slot=self.analyze_opportunities,
            bottom_btn_text="Lookup",
            bottom_btn_slot=self.lookup_from_opportunities,
            hint_fixed_width=220,          # keep the same width for consistency
        )
        v_layout.addWidget(lower_pane)

        return widget
        
    # @staticmethod
    def _configure_text_edit(self, edit: QTextEdit, edit_hints: QTextEdit):
        # print(f"Configuring new pane {edit}")
        edit.setReadOnly(False)                     # allow programmatic writes
        edit.setFixedWidth(self.coach_hints_width)  
        edit_hints.setReadOnly(False)
        edit_hints.setFixedWidth(self.base_width - self.coach_hints_width)     
        # (optional) keep the height flexible but prevent horizontal stretching
        edit.setSizePolicy(QSizePolicy.Policy.Fixed,
                           QSizePolicy.Policy.Expanding)
        edit_hints.setSizePolicy(QSizePolicy.Policy.Fixed,
                           QSizePolicy.Policy.Expanding)
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
        edit_hints.setStyleSheet(
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

        hbox = QHBoxLayout()
        hbox.setContentsMargins(0, 0, 0, 0)         # no extra margins inside
        hbox.addWidget(edit_hints)                          # left‑hand stretch
        hbox.addWidget(edit)                       # edit pushed to the right
        # The horizontal layout itself is added to the main vertical layout
        container = QWidget()
        container.setLayout(hbox)
        return container

    def _make_three_column_pane(
        self,
        tape_edit: QTextEdit,
        hint_edit: QTextEdit,
        top_btn_text: str,
        top_btn_slot,
        bottom_btn_text: str,
        bottom_btn_slot,
        hint_fixed_width: int = 200,   # you can change this value
    ) -> QWidget:
        """
        Returns a QWidget containing:
            • a vertical button column (top/bottom)
            • the main QTextEdit (expanding)
            • a hint QTextEdit with a fixed width
        """
        # ----- Configure the QTextEdits (same for both upper and lower panes) -----
        # print(f"Configuring new pane {edit}")
        tape_edit.setReadOnly(False)                     # allow programmatic writes
        tape_edit.setFixedWidth(self.coach_hints_width)  
        # (optional) keep the height flexible but prevent horizontal stretching
        tape_edit.setSizePolicy(QSizePolicy.Policy.Fixed,
                           QSizePolicy.Policy.Expanding)
        # In Qt6 the wrap mode enum lives under LineWrapMode
        tape_edit.setLineWrapMode(QTextEdit.LineWrapMode.NoWrap)
        # Scroll‑bar policies are now under Qt.ScrollBarPolicy
        tape_edit.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOn)
        tape_edit.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        tape_edit.setStyleSheet(
            """
            QTextEdit {
                background-color: #fafafa;
                font-family: Consolas, monospace;
                font-size: 10pt;
                padding: 2px;
            }
            """
        )
        hint_edit.setSizePolicy(QSizePolicy.Policy.Fixed,
                           QSizePolicy.Policy.Expanding)
        hint_edit.setReadOnly(False)
        hint_edit.setFixedWidth(self.base_width - self.coach_hints_width)     
        hint_edit.setStyleSheet(
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

        # ----- Outer horizontal layout (the three columns) -----
        outer = QWidget()
        h_layout = QHBoxLayout(outer)
        h_layout.setContentsMargins(0, 0, 0, 0)
        h_layout.setSpacing(6)                     # space between columns

        # ----- 1️⃣ Left column: vertical button stack ----------
        btn_col = QWidget()
        v_layout = QVBoxLayout(btn_col)
        v_layout.setContentsMargins(0, 0, 0, 0)
        v_layout.setSpacing(2)

        # Top button
        btn_top = QPushButton(top_btn_text, self)
        btn_top.setSizePolicy(
            QSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Fixed)
        )
        btn_top.clicked.connect(top_btn_slot)
        v_layout.addWidget(btn_top)

        # Bottom button
        btn_bottom = QPushButton(bottom_btn_text, self)
        btn_bottom.setSizePolicy(
            QSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Fixed)
        )
        btn_bottom.clicked.connect(bottom_btn_slot)
        v_layout.addWidget(btn_bottom)

        # Keep the button column as narrow as it needs to be
        btn_col.setSizePolicy(
            QSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Expanding)
        )
        h_layout.addWidget(btn_col)

        # ----- 2️⃣ Middle column: the main QTextEdit (expanding) -----
        hint_edit.setSizePolicy(
            QSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        )
        h_layout.addWidget(hint_edit)

        # ----- 3️⃣ Right column: the hint QTextEdit (fixed width) -----
        tape_edit.setSizePolicy(
            QSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Expanding)
        )
        tape_edit.setMinimumWidth(hint_fixed_width)
        tape_edit.setMaximumWidth(hint_fixed_width)   # forces a fixed width
        h_layout.addWidget(tape_edit)

        return outer

    def analyze_hints(self):
        text = self.upper_tape.toPlainText()
        self.append_log("Analyzing hints...")
        # Placeholder for actual analysis logic
        hint_count = len(text.splitlines())
        self.append_log(f"Hint analysis complete: {hint_count} hints found.")

    def lookup_from_hints(self):
        text = self.upper_tape.toPlainText()
        self.append_log("Looking up hints in dictionary...")
        # Placeholder for actual lookup logic
        words = set(re.findall(r"\b\w+\b", text))
        found = 0
        for word in words:
            if self.composite.find_best_match(word):
                found += 1
        self.append_log(f"Lookup complete: {found}/{len(words)} hints matched in dictionary.")

    def analyze_opportunities(self):
        text = self.lower.toPlainText()
        self.append_log("Analyzing opportunities...")
        # Placeholder for actual analysis logic
        opportunity_count = len(text.splitlines())
        self.append_log(f"Opportunity analysis complete: {opportunity_count} opportunities found.")

    def lookup_from_opportunities(self):
        text = self.lower.toPlainText()
        self.append_log("Looking up opportunities in dictionary...")
        # Placeholder for actual lookup logic
        words = set(re.findall(r"\b\w+\b", text))
        found = 0
        for word in words:
            if self.composite.find_best_match(word):
                found += 1
        self.append_log(f"Lookup complete: {found}/{len(words)} opportunities matched in dictionary.")
    
    # ------------------------------------------------------------------
    # Navigation handling
    # ------------------------------------------------------------------
    def switch_to_tab(self, tab_name: str) -> None:
        """
        Programmatically switch to the given tab by name.
        """
        idx = self.nav_combo.findText(tab_name)
        if idx != -1:
            self.nav_combo.setCurrentIndex(idx)
        else:
            _QW_LOG.warning(f"Tab '{tab_name}' not found in navigation combo.")

    def _on_nav_changed(self, idx: int) -> None:
        """
        I used to resize the window when switching to the Coach. 
        It failed, because the other tabs had minimum sizes, even when invisible. 
        They were too big. I still want to stay pinned to the top right 
        """
        self.stack.setCurrentIndex(idx)

        if idx == 3:                     # Coach page
            self.resize(self.base_width, self.base_height)
            self.status_label.setText("Dashboard: Coach mode")
        else:
            self.resize(self.base_width, self.base_height)
            page_name = self.nav_combo.itemText(idx)
            self.status_label.setText(f"Dashboard: {page_name}")

        # Keep the window glued to the upper‑right corner after a resize
        self._pin_to_upper_right()

    def _pin_to_upper_right(self) -> None:
        geom = QApplication.primaryScreen().availableGeometry()
        x = geom.x() + geom.width() - self.width()
        y = geom.y()
        self.move(x, y)

    def append_log(self, msg: str) -> None:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.log_area.append(f"{timestamp} - {msg}")

    def resizeEvent(self, event) -> None:
        super().resizeEvent(event)
        self._pin_to_upper_right()

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
        self._engine = Expansion_Engine(self._key_output, self._comms_proxy, self.gregg_dict)
        self._key_queue = Key_Queue(self._engine)  
        self._key_input = Key_Input(self._key_queue, self._comms_proxy)
        self._comms_proxy.set_key_input(self._key_input)
        self._key_input.start_listening()
        _QW_LOG.info("Built new Engine")
        self.append_log(f"Built new Engine")
 
    def set_coach_hintlog(self, text: str):
        # print(f"Setting hintlog text to: {text}")
        scrubbed_text = self._scrub_text(text)
        self.upper_tape.setPlainText(scrubbed_text)
        self.upper_tape.verticalScrollBar().setValue(self.upper_tape.verticalScrollBar().maximum())

    def append_coach_hintlog(self, line: str):
        # print(f"Appending to hintlog text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.upper_tape.append(scrubbed_line)
        self.upper_tape.verticalScrollBar().setValue(self.upper_tape.verticalScrollBar().maximum())

    def set_coach_predictions(self, text: str):
        # print(f"Setting predictions text to: {text} for self {self}")
        # print(f"lower is {self.lower_tape}")
        scrubbed_text = self._scrub_text(text)
        # print(f"Setting lower text to scrubbed: {scrubbed_text}")
        self.lower_tape.setPlainText(scrubbed_text)
        # print(f"Setting scrollbar") 
        self.lower_tape.verticalScrollBar().setValue(self.lower_tape.verticalScrollBar().minimum())

    def append_coach_predictions(self, line: str):
        # print(f"Appending to predictions text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.lower_tape.append(scrubbed_line)
        self.lower_tape.verticalScrollBar().setValue(self.lower_tape.verticalScrollBar().minimum())

    def set_coach_misses(self, text: str):
        # print(f"Setting misses text to: {text}")
        scrubbed_text = self._scrub_text(text)
        self.upper_hints.setPlainText(scrubbed_text)
        self.upper_hints.verticalScrollBar().setValue(self.upper_hints.verticalScrollBar().maximum())

    def append_coach_misses(self, line: str):
        # print(f"Appending to misses text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.upper_hints.append(scrubbed_line)
        self.upper_hints.verticalScrollBar().setValue(self.upper_hints.verticalScrollBar().maximum())

    def set_coach_opportunities(self, text: str):
        # print(f"Setting opportunities text to: {text} for self {self}")
        # print(f"lower is {self.lower_tape}")
        scrubbed_text = self._scrub_text(text)
        # print(f"Setting lower text to scrubbed: {scrubbed_text}")
        self.lower_hints.setPlainText(scrubbed_text)
        # print(f"Setting scrollbar") 
        self.lower_hints.verticalScrollBar().setValue(self.lower_hints.verticalScrollBar().minimum())

    def append_coach_opportunities(self, line: str):
        # print(f"Appending to opportunities text: {line}")
        scrubbed_line = self._scrub_line(line)
        self.lower_hints.append(scrubbed_line)
        self.lower_hints.verticalScrollBar().setValue(self.lower_hints.verticalScrollBar().minimum())

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
        self.append_log(f"Notified engine started")


    def on_engine_stopped(self):
        _QW_LOG.info("Notified engine stopped")
        self.btn_start.setEnabled(True)
        self.btn_stop.setEnabled(False)
        self.append_log(f"Notified engine stopped")

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
        self.switch_to_tab("Coach")
        self.append_log(f"Updated credentials")



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

    sys.exit(app.exec())


if __name__ == "__main__":
    main()