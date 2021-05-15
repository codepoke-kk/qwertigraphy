cd "$PsScriptRoot\..\qwertigraph"

& "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in trainer.ahk /out ..\release\trainer.exe /icon coach.ico

& "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in chorder.ahk /out ..\release\chorder.exe /icon coach.ico
