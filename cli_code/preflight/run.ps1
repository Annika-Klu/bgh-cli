. "$PSScriptRoot/loadClassesAndModules.ps1"
. "$PSScriptRoot/installRequirements.ps1"

$envPath = Join-Path $PWD ".env"
Get-DotEnv -Path $envPath

function Set-Encoding {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
    [Console]::InputEncoding = [Text.UTF8Encoding]::new()
}

function Test-PSVersion {
    $minVersion = [Version]"5.1"
    if ($PSVersionTable.PSVersion -lt $minVersion) {
        Write-Warning "Warnung: Deine PowerShell-Version ist $($PSVersionTable.PSVersion). Für dieses CLI wird mindestens Version $minVersion empfohlen."
    }
}

try {
    Set-Encoding
    Test-PSVersion
} catch {
    $log.Write("ERROR in preflight/run.ps1: UTF-8 encoding could not be set: $($_.Exception.Message)")
}
