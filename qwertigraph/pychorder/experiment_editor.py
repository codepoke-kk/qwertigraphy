import csv
import sys
from pathlib import Path
from typing import List, Dict

from PyQt6.QtCore import Qt, QSortFilterProxyModel, QModelIndex
from PyQt6.QtGui import QStandardItemModel, QStandardItem
from PyQt6.QtWidgets import (
    QApplication,
    QWidget, QTabWidget,
    QHBoxLayout,
    QVBoxLayout,
    QLineEdit,
    QLabel,
    QTableView,
    QPushButton,
    QComboBox,
    QHeaderView,
    QMessageBox,
)


# ----------------------------------------------------------------------
# Helper: simple CSV ↔ list‑of‑lists conversion (replace with your own)
# ----------------------------------------------------------------------
def load_csv(path: Path) -> List[List[str]]:
    """Read a CSV file (comma‑separated, no quoting) into a list of rows."""
    if not path.is_file():
        return []
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.reader(f))


def save_csv(path: Path, rows: List[List[str]]) -> None:
    """Write a list of rows to a CSV file."""
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(rows)


# ----------------------------------------------------------------------
# Main widget – the dictionary editor tab
# ----------------------------------------------------------------------
class DictionaryEditorTab(QWidget):
    """
    One tab that lets the user filter, view, edit and add entries
    to a collection of source dictionaries (CSV files).
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
    def __init__(self, source_folder: Path, parent=None):
        super().__init__(parent)

        self.source_folder = source_folder
        self.source_files: List[Path] = []          # e.g. ["dict1.csv", "dict2.csv"]
        self.models_by_source: Dict[Path, QStandardItemModel] = {}

        self._setup_ui()
        self._load_all_sources()

    # ------------------------------------------------------------------
    # UI building
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

        # 7th field is a combo‑box that selects the source dictionary
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

        # Placeholder button names (feel free to extend)
        button_names = ["S", "D", "G", "LY", "ALLY", "X", "Y", "Z", "A", "B", "C", "D2"]
        for name in button_names:
            btn = QPushButton(name, self)
            btn.clicked.connect(lambda _, n=name: self._rapid_button_clicked(n))
            right_vbox.addWidget(btn)

        right_vbox.addStretch()   # push buttons to the top

        # ---------- 3️⃣ Bottom bar (Save) ----------
        bottom_bar = QHBoxLayout()
        self.btn_save_all = QPushButton("Save All Dictionaries", self)
        self.btn_save_all.clicked.connect(self._save_all_sources)
        bottom_bar.addStretch()
        bottom_bar.addWidget(self.btn_save_all)
        main_layout.addLayout(bottom_bar)

        # ----- Model / Proxy setup (empty for now) -----
        self.base_model = QStandardItemModel(0, self.COLUMN_COUNT, self)
        self.base_model.setHorizontalHeaderLabels(self.HEADER_LABELS)

        self.proxy = QSortFilterProxyModel(self)
        self.proxy.setSourceModel(self.base_model)
        self.proxy.setFilterKeyColumn(-1)   # we will filter manually per column
        self.table_view.setModel(self.proxy)

        # Make columns stretch to fill the view
        header = self.table_view.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.ResizeMode.Stretch)

    # ------------------------------------------------------------------
    # Loading all CSV files from the folder
    # ------------------------------------------------------------------
    def _load_all_sources(self) -> None:
        """
        Scan ``self.source_folder`` for *.csv files, load each into its own
        QStandardItemModel, and merge them into the *display* model.
        """
        if not self.source_folder.is_dir():
            QMessageBox.warning(self, "Folder missing",
                                f"The folder {self.source_folder} does not exist.")
            return

        self.source_files = sorted(self.source_folder.glob("*.csv"))
        if not self.source_files:
            QMessageBox.information(self, "No dictionaries",
                                    f"No CSV files found in {self.source_folder}.")
            return

        # Clear any previous data
        self.base_model.removeRows(0, self.base_model.rowCount())
        self.models_by_source.clear()
        self.source_combo.clear()

        for csv_path in self.source_files:
            rows = load_csv(csv_path)
            model = QStandardItemModel(len(rows), self.COLUMN_COUNT, self)
            model.setHorizontalHeaderLabels(self.HEADER_LABELS)

            for r, row in enumerate(rows):
                for c in range(self.COLUMN_COUNT):
                    # Guard against short rows
                    txt = row[c] if c < len(row) else ""
                    model.setItem(r, c, QStandardItem(txt))

            self.models_by_source[csv_path] = model

            # Append the rows of this source to the *global* display model
            for r in range(model.rowCount()):
                items = [model.item(r, c).clone() for c in range(self.COLUMN_COUNT)]
                self.base_model.appendRow(items)

            # Populate the source‑selector combo box
            self.source_combo.addItem(csv_path.name, csv_path)

    # ------------------------------------------------------------------
    # Filtering logic – called whenever any filter edit changes
    # ------------------------------------------------------------------
    def _apply_filters(self) -> None:
        """
        Re‑evaluate all rows against the 7 filter strings.
        The proxy model is used only for sorting; we implement the
        per‑column text filter manually.
        """
        # Build a list of (column, pattern) pairs, ignoring empty patterns
        patterns = [(col, edit.text().strip().lower())
                    for col, edit in enumerate(self.filter_edits)
                    if edit.text().strip()]

        # Hide/show rows based on the patterns
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
    def _load_row_into_editors(self, index: QModelIndex) -> None:
        """
        ``index`` is a proxy‑model index; translate it to the source model.
        """
        src_index = self.proxy.mapToSource(index)
        row = src_index.row()

        for col in range(self.COLUMN_COUNT - 1):   # first six plain edits
            txt = self.base_model.item(row, col).text()
            self.editor_edits[col].setText(txt)

        # 7th column – source selector
        src_name = self.base_model.item(row, self.COLUMN_COUNT - 1).text()
        idx = self.source_combo.findText(src_name)
        if idx != -1:
            self.source_combo.setCurrentIndex(idx)

    # ------------------------------------------------------------------
    # Add a new entry (or replace the currently selected one)
    # ------------------------------------------------------------------
    def _add_or_update_entry(self) -> None:
        """
        Gather the 7 values from the editor widgets and append a new row
        to the *selected* source dictionary. The global view model is also
        updated so the new row appears instantly.
        """
        # 1️⃣ Gather values
        values = [le.text() for le in self.editor_edits]
        source_path: Path = self.source_combo.currentData()
        if not source_path:
            QMessageBox.warning(self, "No source selected",
                                "Please select a source dictionary in the last field.")
            return
        values.append(source_path.name)   # column 7 = file name

        # 2️⃣ Append to the *source‑specific* model
        src_model = self.models_by_source[source_path]
        items = [QStandardItem(v) for v in values]
        src_model.appendRow(items)

        # 3️⃣ Also append to the *global* display model
        self.base_model.appendRow([itm.clone() for itm in items])

        # 4️⃣ Clear editor fields (optional)
        for le in self.editor_edits:
            le.clear()
        self.source_combo.setCurrentIndex(-1)

        # 5️⃣ Refresh filter view (new row might be hidden)
        self._apply_filters()

    # ------------------------------------------------------------------
    # Placeholder for rapid‑creation buttons
    # ------------------------------------------------------------------
    def _rapid_button_clicked(self, name: str) -> None:
        """
        At the moment we just show a message – later you can pre‑fill
        the editor fields with a template for the given entry type.
        """
        QMessageBox.information(self, "Rapid button",
                                f"You clicked the rapid‑creation button “{name}”.\n"
                                "Implement the template logic here.")

    # ------------------------------------------------------------------
    # Save all source dictionaries back to CSV
    # ------------------------------------------------------------------
    def _save_all_sources(self) -> None:
        """
        Iterate over each source model and write its rows to the original CSV.
        """
        for path, model in self.models_by_source.items():
            rows = []
            for r in range(model.rowCount()):
                row = [model.item(r, c).text() for c in range(self.COLUMN_COUNT)]
                rows.append(row)
            try:
                save_csv(path, rows)
            except Exception as exc:
                QMessageBox.critical(self, "Save failed",
                                     f"Could not write {path}:\n{exc}")
                return

        QMessageBox.information(self, "Saved",
                                "All dictionaries have been saved successfully.")

# ----------------------------------------------------------------------
# Demo harness – put the tab into a QTabWidget for quick testing
# ----------------------------------------------------------------------
if __name__ == "__main__":
    app = QApplication(sys.argv)

    # Folder that contains your CSV dictionaries (create it if needed)
    demo_folder = Path.cwd() / "demo_dicts"
    demo_folder.mkdir(exist_ok=True)

    # Create a simple main window with a QTabWidget
    main_win = QWidget()
    main_layout = QVBoxLayout(main_win)

    tabs = QTabWidget()
    editor_tab = DictionaryEditorTab(demo_folder)
    tabs.addTab(editor_tab, "Dictionary Editor")
    main_layout.addWidget(tabs)

    main_win.resize(1000, 600)
    main_win.show()
    sys.exit(app.exec())