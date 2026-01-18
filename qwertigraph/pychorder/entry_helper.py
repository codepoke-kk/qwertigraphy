import json
import re
from pathlib import Path
from typing import List, Dict
from log_factory import get_logger
from PyQt6.QtWidgets import (
    QMessageBox,
    QPushButton,
    QAbstractButton,
)
from PyQt6.QtCore import Qt 
from dictionary import Entry

class Entry_Helper:
    _log = get_logger('HELPR')
    patterns_file = Path("uniform_patterns.json") 
    patterns = json.loads(patterns_file.read_text(encoding="utf-8"))

    def __init__(self, main_window, composite):
        self.main_window = main_window
        self.composite = composite
        self._log.info("Entry Helper initialized")

    def qwerd_and_keyer_from_word_and_form(self, word: str, form: str) -> str:
        qwerd = self._transform_form(word, form, self.patterns).capitalize()
        
        collision_entry = self.composite.read(qwerd)
        keyer = ""
        if collision_entry:
            keyer = self._get_keyer_from_qwerd(qwerd, collision_entry)
            if keyer == 'CANCEL' or keyer == 'FAILED':
                return '', ''
        return qwerd + keyer, keyer

    def _get_keyer_from_qwerd(self, qwerd: str, collision: Entry) -> str:
        keyer = ''
        collision_o = self.composite.read(f"{qwerd}o")
        collision_u = self.composite.read(f"{qwerd}u")
        collision_i = self.composite.read(f"{qwerd}i")
        message = f"Qwerd '{qwerd}' already exists as '{collision.word}'.\n"
        message += f"Press ∅ to replace qwerd '{qwerd}' overwriting '{collision.word}'\n"
        if not collision_o:
            message += f"Press o to use available qwerd '{qwerd}o'\n"
        else:
            message += f"Press o to replace qwerd '{qwerd}o' overwriting '{collision_o.word}'\n"
        if not collision_u:
            message += f"Press u to use available qwerd '{qwerd}u'\n"
        else:
            message += f"Press u to replace qwerd '{qwerd}u' overwriting '{collision_u.word}'\n"
        if not collision_i:
            message += f"Press i to use available qwerd '{qwerd}i'\n"
        else:
            message += f"Press i to replace qwerd '{qwerd}i' overwriting '{collision_i.word}'\n"

        msg = QMessageBox(self.main_window)
        msg.setWindowTitle("Qwerd collision")
        msg.setIcon(QMessageBox.Icon.Warning)
        msg.setText(message)

        btn_overwrite = QPushButton("∅")    
        btn_o = QPushButton("o")
        btn_u = QPushButton("u")
        btn_i = QPushButton("i")
        btn_overwrite = msg.addButton("∅", QMessageBox.ButtonRole.AcceptRole)
        btn_o         = msg.addButton("o", QMessageBox.ButtonRole.AcceptRole)
        btn_u         = msg.addButton("u", QMessageBox.ButtonRole.AcceptRole)
        btn_i         = msg.addButton("i", QMessageBox.ButtonRole.AcceptRole)

        # Standard Cancel button – Qt6 prefers the overload that takes a StandardButton.
        btn_cancel = msg.addButton(QMessageBox.StandardButton.Cancel)
        msg.setDefaultButton(btn_overwrite)

        msg.exec()    
        clicked: QAbstractButton = msg.clickedButton()

        clicked = msg.clickedButton()
        if clicked == btn_overwrite:
            return ''
        elif clicked == btn_o:
            return 'o'
        elif clicked == btn_u:
            return 'u'
        elif clicked == btn_i:
            return 'i'
        elif clicked == btn_cancel:
            return 'CANCEL'

        

        return 'FAILED'
    
    def _transform_form(self, word: str, form: str, rules: List[Dict[str, str]]) -> str:
        for rule in rules:
            word_pattern = re.compile(rule["word_pattern"])
            form_pattern = re.compile(rule["form_pattern"])

            if not word_pattern.search(word) and not form_pattern.search(form):
                continue

            # Second substitution (abbreviation pattern)
            form = form_pattern.sub(rule["replace"], form)

        return form

'''
 No longer works without building a full UI context, but left here for reference.
 if __name__ == "__main__":
    # Replace this path with wherever you stored the JSON snippet.
    entry_helper = Entry_Helper()

    start_word = 'Intrepid'
    start_form = "n-/-p-d"
    qwerd, keyer = entry_helper.qwerd_keyer_from_word_and_form(start_word, start_form)

    print(f"Input : {start_form} ({start_word})")
    print(f"Output: {qwerd} - {keyer}")   # Expected: nnox

'''