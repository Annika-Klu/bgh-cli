param(
    [string]$Command
)

. "$PSScriptRoot/loadClassesAndModules.ps1"
. "$PSScriptRoot/installRequirements.ps1"

function Set-Encoding {
    chcp 65001 > $null

    $utf8 = New-Object System.Text.UTF8Encoding $false

    [Console]::InputEncoding  = $utf8
    [Console]::OutputEncoding = $utf8
    $OutputEncoding = $utf8
}

function Test-PSVersion {
    $minVersion = [Version]"5.1"
    if ($PSVersionTable.PSVersion -lt $minVersion) {
        Write-Warning "Warnung: Deine PowerShell-Version ist $($PSVersionTable.PSVersion). Für dieses CLI wird mindestens Version $minVersion empfohlen."
    }
}

function Test-CliVersion {
    $latestRelease = Get-LatestRelease -GitHubToken $GH_TOKEN -ReleasesUrl $RELEASES_URL
    $versionRegex = "(?<=^v)(\d+\.\d+\.\d+)"
    if ($latestRelease.tag_name -match $versionRegex) {
        $latestReleaseVersionStr = $matches[0]
        $latestReleaseVersion = [Version] $latestReleaseVersionStr
    } else {
        Write-Warning "Keine Versionsangabe für den neuen Release gefunden."
    }
    if ($VERSION -match $versionRegex) {
        $currentVersionStr = $matches[0]
        $currentVersion = [Version]$currentVersionStr
    }
    if ($currentVersion -lt $latestReleaseVersion) {
        Out-Message "[HINWEIS] BGH-CLI $($latestRelease.tag_name) ist jetzt verfügbar." warning
        Out-Message "Deine Version ist $VERSION. Führe 'bgh update' aus, um sie zu aktualisieren.`n" warning
    }
}

function Write-PreflightError {
    param(
        [Parameter(Mandatory)]
        [string]$ErrMsg
    )

    $fileName = "bgh-cli.startfehler.txt"
    try {
        Write-Host "Fehler bei CLI-Start $ErrMsg"
        $desktop = [Environment]::GetFolderPath("Desktop")
        $logFile = Join-Path $desktop $fileName

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "[$timestamp] $ErrMsg"

        Add-Content -Path $logFile -Value $entry
    } catch {
        Write-Host "FEHLER beim Schreiben in $($fileName): $($ErrMsg)"
    }
}

$initFile = Join-Path $PWD "init"

try {
    if ((Test-Path $initFile) -or ($Command -eq "init[system]")) {
        Get-DotEnv
        Set-CliEnv
        Remove-Item $initFile -ErrorAction SilentlyContinue
    }
    Get-DotEnv
    Set-Encoding
    Test-PSVersion
    if ($Command -ne "update") { Test-CliVersion }
} catch {
    Write-PreflightError -ErrMsg "ERROR in preflight run: $($_.Exception.Message)"
}