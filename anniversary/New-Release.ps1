cd "$PsScriptRoot\..\scripts"

$filters = @('*.txt', '*.csv', '*.html')
foreach ($filter in $filters) {
$files = dir -filter $filter
    foreach ($file in $files) {
        ";@Ahk2Exe-AddResource $($file.name)"
    }
}

& "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in Qwertigraph.ahk /out ..\release\Qwertigraph.exe /icon coach.ico
