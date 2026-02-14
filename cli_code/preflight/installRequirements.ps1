$ErrorActionPreference = "Stop"

$requirements = Import-PowerShellDataFile -Path "$PWD/requirements.psd1"

function Assert-ElevatedScriptRun {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Error "Bitte PowerShell als Administrator starten und den Befehl erneut ausführen." -ErrorAction Stop
    }
}

Assert-ElevatedScriptRun
foreach ($mod in $requirements.RequiredModules) {
    $name = $mod.Name
    $minVersion = $mod.MinimumVersion

    $installed = Get-Module -ListAvailable -Name $name | Where-Object { $_.Version -ge [Version]$minVersion }
    if (-not $installed) {
        Out-Message "Installiere Modul $name ($($mod.Description))..."
        Install-Module -Name $name -MinimumVersion $minVersion -Force -Scope CurrentUser
    }
}