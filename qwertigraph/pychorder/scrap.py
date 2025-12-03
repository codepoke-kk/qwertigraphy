#!/usr/bin/env python3
import sys
from PyQt6.QtWidgets import QApplication
from vaulter import Vaulter

def main():
    app = QApplication(sys.argv)

    vault = Vaulter()
    # Pass the `app` as the parent – the dialog will be modal to the app.
    vault.new_base_password(parent=app.activeWindow())

    # Show the masked credentials in the console (for demo purposes)
    vault.output_base_username_password()

    # Exit cleanly
    sys.exit(0)

if __name__ == "__main__":
    main()