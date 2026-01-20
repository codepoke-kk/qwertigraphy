
f10::
    {
        ; Desired size
        NewWidth  := A_ScreenWidth  - 220   ; screen width minus 180 px
        NewHeight := A_ScreenHeight        ; full screen height (change if you want less)

        ; Optional offset from the screen edges
        OffsetX := 3
        OffsetY := 3

        ; Move & resize the active window (A = the window that currently has focus)
        WinMove, A, , OffsetX, OffsetY, NewWidth, NewHeight
    }
    return
; Insert::Backspace
; NumpadIns::Backspace