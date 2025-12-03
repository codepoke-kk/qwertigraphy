import logging
from typing import Optional, Tuple

from PyQt6.QtWidgets import (
    QInputDialog,
    QMessageBox,
    QWidget, QLineEdit
)
from log_factory import get_logger   # keep your existing logger factory


class Vaulter:
    """
    Collects a username and a password using **Qt modal dialogs**.
    All UI calls are non‑blocking for the rest of the application because
    they run inside the already‑running QEventLoop.
    """

    _log: logging.Logger = get_logger("VAULT")

    def __init__(self) -> None:
        self._username: Optional[str] = None
        self._password: Optional[str] = None
        self._log.info("Initiated Vaulter")

    # -----------------------------------------------------------------
    # Public helpers that other parts of the program call
    # -----------------------------------------------------------------
    def output_base_password(self) -> None:
        """Log the password (masked). If we don’t have one yet, ask for it."""
        if not self._password:
            self.new_base_password()
        if self._password:
            masked = "*" * len(self._password)
            self._log.info(f"Expanding to password: {masked}")

    def output_base_username_password(self) -> None:
        """Log username + masked password. Prompt if missing."""
        if not self._username or not self._password:
            self.new_base_password()
        if self._username and self._password:
            masked = "*" * len(self._password)
            self._log.info(
                f"Expanding to username/password: {self._username} / {masked}"
            )

    # -----------------------------------------------------------------
    # Core UI – asks for username **and** password in two consecutive
    # Qt modal dialogs.  Returns a tuple (username, password) or None.
    # -----------------------------------------------------------------
    def new_base_password(self, parent: Optional[QWidget] = None) -> Optional[Tuple[str, str]]:
        """
        Show two modal dialogs (username then password) and store the results.
        If the user cancels either step, the method returns ``None`` and leaves
        any previously stored credentials untouched.
        """
        self._log.info("Collecting new base password (Qt dialogs)")

        # If the caller does not supply a parent widget, we use the active
        # top‑level window of the current QApplication (or None if there is none).
        if parent is None:
            # ``QApplication.activeWindow()`` returns the window that currently
            # has focus, which is the most natural parent for a modal dialog.
            from PyQt6.QtWidgets import QApplication

            parent = QApplication.activeWindow()

        # ---------------------------------------------------------
        # 1️⃣  Ask for the username
        # ---------------------------------------------------------
        username, ok = QInputDialog.getText(
            parent,
            "Credentials",
            "Enter base username:",
            echo=QLineEdit.EchoMode.Normal
        )
        if not ok or username == "":
            self._log.debug("Username dialog cancelled")
            return None

        self._username = username.strip()
        self._log.debug(f"Collected username: {self._username}")

        # ---------------------------------------------------------
        # 2️⃣  Ask for the password (masked)
        # ---------------------------------------------------------
        password, ok = QInputDialog.getText(
            parent,
            "Credentials",
            "Enter base password:",
            echo=QLineEdit.EchoMode.Password
        )
        if not ok or password == "":
            self._log.debug("Password dialog cancelled")
            # Reset username to keep the object in a consistent “no‑creds” state
            self._username = None
            return None

        self._password = password
        self._log.debug("Collected password (masked)")

        # ---------------------------------------------------------
        # 3️⃣  Confirmation (optional – nice UX)
        # ---------------------------------------------------------
        QMessageBox.information(
            parent,
            "Credentials stored",
            f"Username **{self._username}** and password have been saved.",
        )

        self._log.debug(
            f"Done collecting credentials: {self._username} / {'*' * len(self._password)}"
        )
        return self._username, self._password

    # -----------------------------------------------------------------
    # Nice representation – never prints the real password
    # -----------------------------------------------------------------
    def __repr__(self) -> str:
        uname = self._username if self._username else "<none>"
        pw_len = len(self._password) if self._password else 0
        return f"<Vaulter username={uname!r} password_length={pw_len}>"