import tkinter as tk
from tkinter import simpledialog, messagebox

def ask_credentials(parent: tk.Tk | None = None) -> tuple[str, str] | None:
    """
    Pops a modal dialog that asks for a username and a password.
    Returns (username, password) or None if the user cancels.
    """
    # If the caller already has a root window, reuse it; otherwise create a hidden one.
    own_root = False
    if parent is None:
        parent = tk.Tk()
        parent.withdraw()   # hide the empty root window
        own_root = True

    # ---- Username -------------------------------------------------
    username = simpledialog.askstring(
        "Credentials", "Enter username:",
        parent=parent,
    )
    if username is None:          # user pressed Cancel
        if own_root:
            parent.destroy()
        return None

    # ---- Password (masked) ----------------------------------------
    password = simpledialog.askstring(
        "Credentials", "Enter password:",
        show="*",                # mask the input
        parent=parent,
    )
    if password is None:
        if own_root:
            parent.destroy()
        return None

    if own_root:
        parent.destroy()        # clean up the hidden root

    return username, password


# -----------------------------------------------------------------
# Demo usage (run this file directly)
# -----------------------------------------------------------------
if __name__ == "__main__":
    creds = ask_credentials()
    if creds:
        user, pwd = creds
        messagebox.showinfo("Result", f"User: {user}\nPass: {pwd}")
    else:
        messagebox.showinfo("Result", "User cancelled")