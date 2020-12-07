<#
This makes the anniversary core dictionary. Each step takes an input file and produces an output file, so 
you can run each file individually to see what it creates. 
#>

& "$PsScriptRoot\Publish-RawFromSource.ps1"
& "$PsScriptRoot\Publish-Formal.ps1"
& "$PsScriptRoot\Publish-Refined.ps1"
& "$PsScriptRoot\Publish-Usage.ps1"
& "$PsScriptRoot\Publish-Lazy.ps1"
& "$PsScriptRoot\Publish-KeyedLazy.ps1"
& "$PsScriptRoot\Publish-Hinted.ps1"
