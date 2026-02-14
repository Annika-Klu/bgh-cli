$ErrorActionPreference = "Stop"

$requirements = Import-PowerShellDataFile -Path "$PWD/requirements.psd1"

function Assert-ElevatedScriptRun {
    param(
        [string]$ModuleName
    )
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        throw [System.Exception] "BGH-CLI muss das Modul '$ModuleName' installieren. Dazu bitte PowerShell als Administrator ausführen und Befehl erneut eingeben."
    }
}

foreach ($mod in $requirements.RequiredModules) {
    $name = $mod.Name
    $minVersion = $mod.MinimumVersion

    $installed = Get-Module -ListAvailable -Name $name | Where-Object { $_.Version -ge [Version]$minVersion }
    if (-not $installed) {
        Assert-ElevatedScriptRun -ModuleName $name
        Out-Message "Installiere Modul $name ($($mod.Description))..."
        Install-Module -Name $name -MinimumVersion $minVersion -Force -Scope CurrentUser
    }
}