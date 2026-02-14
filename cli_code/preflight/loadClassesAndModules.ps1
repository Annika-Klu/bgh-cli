$classesPath = Join-Path $PWD "Classes"
Get-ChildItem -Path $classesPath -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

$modulesPath = Join-Path $PWD "Modules"
Get-ChildItem -Path $modulesPath -Filter *.psm1 -Recurse | ForEach-Object {
    Import-Module $_.FullName -Force
}