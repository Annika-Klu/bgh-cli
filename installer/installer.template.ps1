Add-Type -AssemblyName Microsoft.VisualBasic

$releaseVersion = "__RELEASE_TAG__"
$ReleasesUrl = "__RELEASES_URL__"
$GitHubToken = "__GH_TOKEN__"
$ZipFile = "$env:TEMP\bgh.zip"
$InstallPath = "$env:USERPROFILE\.bgh"
$MainPS1File = Join-Path $InstallPath "bgh.ps1"
$CmdShim = Join-Path $env:USERPROFILE "AppData\Local\Microsoft\WindowsApps\bgh.cmd"
$EnvFile = Join-Path $InstallPath ".env"

function Get-GitHubModule {
    $url = $ReleasesUrl -replace "api.github.com/repos", "raw.githubusercontent.com"
    $url = $url -replace "releases", "master/cli_code/Modules/GitHub.psm1"
    $moduleFilePath = Join-Path $PSScriptRoot "GitHub.psm1"
    Invoke-WebRequest -Uri $url -OutFile $moduleFilePath
    return $moduleFilePath
}

function Assert-Compatibility {
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -lt 5) {
        return "PowerShell-Version 5 oder höher erforderlich. Aktuelle Version: $psVersion"
    }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    if ([version]$os.Version -lt [version]"10.0.0.0") {
        return "Windows 10 oder höher erforderlich. Aktuelles Betriebssystem: $($os.Version)"
    }
    return "OK"
}

function Get-CLICode {
    try {
        $latestRelease = Get-LatestRelease -GitHubToken $GitHubToken -ReleasesUrl $ReleasesUrl
        $cliCode = Get-ReleaseAsset -GitHubToken $GitHubToken -Release $latestRelease -AssetName "bgh-cli.zip"
        Invoke-WebRequest -Uri $cliCode.browser_download_url -OutFile $ZipFile -UseBasicParsing
    } catch {
        throw "ZIP-Datei konnte nicht heruntergeladen werden: $_"
    }
    Expand-Archive -Path $ZipFile -DestinationPath $InstallPath -Force
    Remove-Item $ZipFile -Force
}

function Add-InitFlag {
    $DummyFile = Join-Path $InstallPath "init"
    New-Item -ItemType File -Path $DummyFile | Out-Null
}

function Write-EnvFile {
    $content = @"
RELEASES_URL=$ReleasesUrl
VERSION=$releaseVersion
CT_SUBDOMAIN=__CT_SUBDOMAIN__
GH_TOKEN=$GitHubToken
"@
    Set-Content -Path $EnvFile -Value $content -Encoding UTF8
}

function Set-CmdShim {
    $shimContent = @"
@echo off
PowerShell -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$MainPS1File`" %*
"@
    Set-Content -Path $CmdShim -Value $shimContent -Encoding ASCII
}

try {
    $compatibility = Assert-Compatibility
    if ($compatibility -ne "OK") {
        throw "Inkompatible Umgebung. $compatibility"
    }

    if (!(Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath | Out-Null
    }

    $moduleFilePath = Get-GitHubModule
    Import-Module $moduleFilePath -Force

    Get-CLICode
    if (!(Test-Path $MainPS1File)) {
        throw "Die Haupt-Datei wurde nicht gefunden."
    }
    Add-InitFlag
    Write-EnvFile
    Set-CmdShim

    Remove-Item $moduleFilePath -Force
    [Microsoft.VisualBasic.Interaction]::MsgBox(
        "BGH-CLI wurde erfolgreich installiert.`nDu kannst jetzt in PowerShell den Befehl 'bgh hilfe' verwenden.",
        "OKOnly,Information",
        "Installation abgeschlossen"
    )
} catch {
    if (Test-Path $InstallPath) {
        Remove-Item $InstallPath -Recurse -Force
    }
    [Microsoft.VisualBasic.Interaction]::MsgBox("Fehler bei der Installation: $_", "OKOnly,Critical", "Fehler")
    exit 1
}