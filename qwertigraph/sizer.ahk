f10::
{
    ; Get the work area for the monitor that contains the active window
    SysGet, WA, MonitorWorkArea, %A_Screen%
    ; WALeft, WATop, WARight, WABottom are created

    NewWidth  := (WARight - WALeft) - 270
    NewHeight := (WABottom - WATop)

    OffsetX := WALeft + 3
    OffsetY := WATop  + 3

    WinMove, A, , OffsetX, OffsetY, NewWidth, NewHeight
    return
}
; Insert::Backspace
; NumpadIns::Backspace