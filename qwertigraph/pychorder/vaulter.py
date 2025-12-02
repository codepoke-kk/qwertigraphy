import getpass
from typing import Optional
from log_factory import get_logger
import tkinter as tk
from tkinter import simpledialog, messagebox

class Vaulter:
    _log = get_logger('VAULT')

    def __init__(self):
        self._username: Optional[str] = None
        self._password: Optional[str] = None
        self._log.info('Initiated Vaulter')

    def output_base_password(self):
        if not self._password:
            self.new_base_password()
        self._log.info(f"Expanding to password: {len(self._password) * '*'}")

    def output_base_username_password(self):
        if not self._username or not self._password:
            self.new_base_password()
        self._log.info(f"Expanding to username/password: {self._username} / {len(self._password) * '*'}")

    def new_base_password(self, parent: tk.Tk | None = None) -> tuple[str, str] | None:
        self._log.info("Collecting new base password")

        # If the caller already has a root window, reuse it; otherwise create a hidden one.
        own_root = False
        if parent is None:
            parent = tk.Tk()
            parent.withdraw()   # hide the empty root window
            own_root = True

        # ---- Username -------------------------------------------------
        self._username = simpledialog.askstring(
            "Credentials", "Enter base username:",
            parent=parent,
        )
        if self._username is None:          # user pressed Cancel
            if own_root:
                parent.destroy()
            return None

        self._log.debug(f"Collected username: {self._username}")
        # ---- Password (masked) ----------------------------------------
        self._password = simpledialog.askstring(
            "Credentials", "Enter base password:",
            show="*",                # mask the input
            parent=parent,
        )
        if self._password is None:
            if own_root:
                parent.destroy()
            return None
        self._log.debug(f"Collected password: {self._password}")

        if own_root:
            parent.destroy()        # clean up the hidden root
        
        self._log.debug(f"Done collecting credentials: {self._username} / {len(self._password) * '*'}")

    def __repr__(self) -> str:
        uname = self._username if self._username else "<none>"
        pw_len = len(self._password) if self._password else 0
        return f"<Vaulter username={uname!r} password_length={pw_len}>"


