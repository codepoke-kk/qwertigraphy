# --------------------------------------------------------------
# CompositeDictionary – the façade you already wrote.
# --------------------------------------------------------------
# The real class lives somewhere else in your code base.
# The stub below only shows the public interface that the editor
# expects.  Swap it out for your actual implementation.
# --------------------------------------------------------------
import csv 

class CompositeDictionary:
    """
    Manages many CSV‑based dictionaries behind a simple CRUD API.

    Public methods used by the editor:
        - get_sources() → List[str]                     # names of the CSV files
        - all_entries() → List[List[str]]               # each row = 7 strings
        - add_entry(entry: List[str]) → None            # entry[6] is the source name
        - update_entry(old_entry: List[str],
                      new_entry: List[str]) → None
        - save_all() → None
    """

    def __init__(self, folder: Path):
        self.folder = folder
        self._entries: List[List[str]] = []   # in‑memory cache
        self._load_all()

    # ------------------------------------------------------------------
    # Internal helpers (real implementation will read/write CSVs)
    # ------------------------------------------------------------------
    def _load_all(self) -> None:
        """Populate self._entries from every CSV in self.folder."""
        for csv_path in sorted(self.folder.glob("*.csv")):
            with csv_path.open(newline="", encoding="utf-8") as f:
                for row in csv.reader(f):
                    # Ensure the row has exactly 7 columns; pad if necessary
                    row = list(row)[:7] + [""] * (7 - len(row))
                    # Append the source name (file name) as the 7th column
                    row[6] = csv_path.name
                    self._entries.append(row)

    # ------------------------------------------------------------------
    # Public API used by the UI
    # ------------------------------------------------------------------
    def get_sources(self) -> List[str]:
        """Return a list of unique source‑file names."""
        return sorted({row[6] for row in self._entries})

    def all_entries(self) -> List[List[str]]:
        """Return a shallow copy of every entry (7‑column list)."""
        return [list(r) for r in self._entries]

    def add_entry(self, entry: List[str]) -> None:
        """Append a new entry.  Caller must ensure entry has 7 items."""
        if len(entry) != 7:
            raise ValueError("Entry must contain exactly 7 columns")
        self._entries.append(list(entry))

    def update_entry(self, old_entry: List[str], new_entry: List[str]) -> None:
        """
        Replace *old_entry* with *new_entry*.
        Matching is performed on the full 7‑column list (including source).
        """
        try:
            idx = self._entries.index(old_entry)
        except ValueError:
            raise ValueError("Old entry not found in dictionary")
        self._entries[idx] = list(new_entry)

    def save_all(self) -> None:
        """Write each source back to its CSV file."""
        # Group rows by source name
        rows_by_source: Dict[str, List[List[str]]] = {}
        for row in self._entries:
            src = row[6]
            rows_by_source.setdefault(src, []).append(row[:6])   # drop source column

        for src_name, rows in rows_by_source.items():
            csv_path = self.folder / src_name
            with csv_path.open("w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerows(rows)

import sys
from pathlib import Path
from typing import List

from PyQt6.QtCore import Qt, QSortFilterProxyModel, QModelIndex
from PyQt6.QtGui import QStandardItemModel, QStandardItem
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QTabWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLineEdit,
    QLabel,
    QTableView,
    QPushButton,
    QComboBox,
    QHeaderView,
    QMessageBox,
)

# ----------------------------------------------------------------------
# Import your real CompositeDictionary implementation here.
# For this example we use the stub defined above.
# ----------------------------------------------------------------------
# from your_module import CompositeDictionary
# (the stub is defined earlier in this file for a self‑contained demo)
# ----------------------------------------------------------------------


class DictionaryEditorTab(QWidget):
    """
    UI that works **against** a CompositeDictionary instance.
    The editor does not know anything about CSV files – it only talks
    to the composite via its CRUD API.
    """

    COLUMN_COUNT = 7
    HEADER_LABELS = [
        "Col 1",
        "Col 2",
        "Col 3",
        "Col 4",
        "Col 5",
        "Col 6",
        "Source",   # 7th column – identifies the source dictionary
    ]

    # ------------------------------------------------------------------
    # Construction
    # ------------------------------------------------------------------
    def __init__(self, composite: CompositeDictionary, parent=None):
        super().__init__(parent)

        self.composite = composite                     # <-- the façade
        self.base_model = QStandardItemModel(0, self.COLUMN_COUNT, self)
        self.base_model.setHorizontalHeaderLabels(self.HEADER_LABELS)

        self.proxy = QSortFilterProxyModel(self)
        self.proxy.setSourceModel(self.base_model)
        self.proxy.setFilterKeyColumn(-1)   # we filter manually per column

        self._setup_ui()
        self._populate_ui_from_composite()

    # ------------------------------------------------------------------
    # UI building (unchanged apart from data source)
    # ------------------------------------------------------------------
    def _setup_ui(self) -> None:
        main_layout = QVBoxLayout(self)

        # ---------- 1️⃣ Filter bar ----------
        self.filter_edits: List[QLineEdit] = []
        filter_bar = QHBoxLayout()
        for col in range(self.COLUMN_COUNT):
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
        self.table_view.doubleClicked.connect(self._load_row_into_editors)
        left_vbox.addWidget(self.table_view)

        # ----- Edit bar (7 fields) -----
        edit_bar = QHBoxLayout()
        self.editor_edits: List[QLineEdit] = []
        for col in range(self.COLUMN_COUNT - 1):          # first 6 are plain QLineEdit
            le = QLineEdit(self)
            le.setPlaceholderText(f"col {col + 1}")
            self.editor_edits.append(le)
            edit_bar.addWidget(le)

        # 7th field – source selector (populated from composite)
        self.source_combo = QComboBox(self)
        edit_bar.addWidget(self.source_combo)

        # Add / Update button
        self.btn_add_update = QPushButton("Add / Update", self)
        self.btn_add_update.clicked.connect(self._add_or_update_entry)
        edit_bar.addWidget(self.btn_add_update)

        left_vbox.addLayout(edit_bar)

        # ----- Right pane : rapid‑creation buttons -----
        right_vbox = QVBoxLayout()
        central_hbox.addLayout(right_vbox)

        button_names = ["S", "D", "G", "LY", "ALLY", "X", "Y", "Z", "A", "B", "C", "D2"]
        for name in button_names:
            btn = QPushButton(name, self)
            btn.clicked.connect(lambda _, n=name: self._rapid_button_clicked(n))
            right_vbox.addWidget(btn)

        right_vbox.addStretch()

        # ---------- 3️⃣ Bottom bar (Save) ----------
        bottom_bar = QHBoxLayout()
        self.btn_save_all = QPushButton("Save All Dictionaries", self)
        self.btn_save_all.clicked.connect(self._save_all)
        bottom_bar.addStretch()
        bottom_bar.addWidget(self.btn_save_all)
        main_layout.addLayout(bottom_bar)

        # ----- Model / View wiring -----
        self.table_view.setModel(self.proxy)

        header = self.table_view.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.ResizeMode.Stretch)

    # ------------------------------------------------------------------
    # Populate UI from the CompositeDictionary
    # ------------------------------------------------------------------
    def _populate_ui_from_composite(self) -> None:
        """Load all entries and source names into the UI."""
        # 1️⃣ Fill the source combo box
        self.source_combo.clear()
        for src_name in self.composite.get_sources():
            self.source_combo.addItem(src_name)

        # 2️⃣ Load every entry into the base model
        self.base_model.removeRows(0, self.base_model.rowCount())
        for entry in self.composite.all_entries():          # entry is List[str] length 7
            items = [QStandardItem(str(cell)) for cell in entry]
            self.base_model.appendRow(items)

    # ------------------------------------------------------------------
    # Filtering logic – same as before, just operates on the base model
    # ------------------------------------------------------------------
    def _apply_filters(self) -> None:
        patterns = [
            (col, edit.text().strip().lower())
            for col, edit in enumerate(self.filter_edits)
            if edit.text().strip()
        ]

        for row in range(self.base_model.rowCount()):
            match = True
            for col, pat in patterns:
                cell_text = self.base_model.item(row, col).text().lower()
                if pat not in cell_text:
                    match = False
                    break
            self.table_view.setRowHidden(row, not match)

    # ------------------------------------------------------------------
    # Load a double‑clicked row into the editing fields
    # ------------------------------------------------------------------
    def _load_row_into_editors(self, proxy_index: QModelIndex) -> None:
        src_index = self.proxy.mapToSource(proxy_index)
        row = src_index.row()

        # Populate the six plain editors
        for col in range(self.COLUMN_COUNT - 1):
            txt = self.base_model.item(row, col).text()
            self.editor_edits[col].setText(txt)

        # Populate the source combo
        src_name = self.base_model.item(row, self.COLUMN_COUNT - 1).text()
        idx = self.source_combo.findText(src_name)
        if idx != -1:
            self.source_combo.setCurrentIndex(idx)

        # Store the *original* row data so we can perform an update later
        self._currently_loaded_row = [self.base_model.item(row, c).text()
                                      for c in range(self.COLUMN_COUNT)]

    # ------------------------------------------------------------------
    # Add a new entry or update the one that is currently loaded
    # ------------------------------------------------------------------
    def _add_or_update_entry(self) -> None:
        """
        If a row was previously loaded via double‑click, we treat the
        operation as an **update**; otherwise it is an **add**.
        """
        # Gather the 7 values from the UI
        new_values = [le.text() for le in self.editor_edits]
        src_name = self.source_combo.currentText()
        if not src_name:
            QMessageBox.warning(self, "Missing source",
                                "Select a source dictionary in the last field.")
            return
        new_values.append(src_name)          # column 7 = source name

        # Decide whether we are updating or adding
        if hasattr(self, "_currently_loaded_row"):
            # ----- UPDATE -----
            try:
                self.composite.update_entry(self._currently_loaded_row,
                                            new_values)
            except ValueError as exc:
                QMessageBox.critical(self, "Update failed", str(exc))
                return
            # Reflect the change in the view model
            # Find the row that matches the old entry (unique because we kept it)
            for r in range(self.base_model.rowCount()):
                row_data = [self.base_model.item(r, c).text()
                            for c in range(self.COLUMN_COUNT)]
                if row_data == self._currently_loaded_row:
                    for c, val in enumerate(new_values):
                        self.base_model.item(r, c).setText(val)
                    break
            del self._currently_loaded_row   # clear the “editing” flag
        else:
            # ----- ADD -----
            self.composite.add_entry(new_values)
            items = [QStandardItem(v) for v in new_values]
            self.base_model.appendRow(items)

        # Clear the editor fields for the next operation
        for le in self.editor_edits:
            le.clear()
        self.source_combo.setCurrentIndex(-1)

        # Re‑apply filters so a newly added row appears/disappears correctly
        self._apply_filters()

    # ------------------------------------------------------------------
    # Placeholder for rapid‑creation buttons
    # ------------------------------------------------------------------
    def _rapid_button_clicked(self, name: str) -> None:
        QMessageBox.information(
            self,
            "Rapid button",
            f"You clicked the rapid‑creation button “{name}”.\n"
            "Implement the template logic here."
        )

    # ------------------------------------------------------------------
    # Save everything via the composite
    # ------------------------------------------------------------------
    def _save_all(self) -> None:
        try:
            self.composite.save_all()
        except Exception as exc:          # pragma: no cover – defensive
            QMessageBox.critical(self, "Save failed", f"{exc}")
            return
        QMessageBox.information(self, "Saved",
                                "All dictionaries have been saved successfully.")


# ----------------------------------------------------------------------
# Demo harness – shows the tab inside a QTabWidget.
# ----------------------------------------------------------------------
if __name__ == "__main__":
    app = QApplication(sys.argv)

    # Folder that contains your CSV dictionaries (create it if needed)
    demo_folder = Path("dictionaries")
    demo_folder.mkdir(exist_ok=True)

    # Instantiate the composite façade
    composite = CompositeDictionary(demo_folder)

    # Build the UI
    main_win = QWidget()
    main_layout = QVBoxLayout(main_win)

    tabs = QTabWidget()
    editor_tab = DictionaryEditorTab(composite)
    tabs.addTab(editor_tab, "Dictionary Editor")
    main_layout.addWidget(tabs)

    main_win.resize(1000, 600)
    main_win.show()
    sys.exit(app.exec())