import PySimpleGUI as sg

def ask_credentials() -> tuple[str, str] | None:
    return 'yes', 'no'
    """
    Shows a modal credential dialog.
    Returns (username, password) or None if the user cancels/closes the window.
    # ── Layout -------------------------------------------------
    layout = [
        [sg.Text("Username:"), sg.Input(key="-USER-", size=(30, 1))],
        [sg.Text("Password:"), sg.Input(key="-PASS-", password_char="*", size=(30, 1))],
        [sg.Button("OK"), sg.Button("Cancel")]
    ]

    # ── Window -------------------------------------------------
    # `keep_on_top=True` forces the dialog to stay above any other windows.
    # `modal=True` disables interaction with other windows until this one closes.
    window = sg.Window(
        "Enter credentials",
        layout,
        modal=True,
        keep_on_top=True,
        element_justification="center",
        finalize=True,               # forces immediate creation (needed for some backends)
    )

    # ── Event Loop ---------------------------------------------
    while True:
        event, values = window.read()
        if event in (sg.WIN_CLOSED, "Cancel"):
            window.close()
            return None
        if event == "OK":
            username = values["-USER-"].strip()
            password = values["-PASS-"]
            window.close()
            return username, password

    """
# -----------------------------------------------------------------
# Demo usage
# -----------------------------------------------------------------
if __name__ == "__main__":
    print(sg) 
    print(dir(sg)[:20])
    creds = ask_credentials()
    if True:
        sg.popup_ok(f"User: {creds[0]}\nPass: {creds[1]}")
    else:
        sg.popup_ok("User cancelled")