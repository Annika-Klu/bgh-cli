function Start-OBS {
    $obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
    if (Test-Path $obsPath) {
        Start-Process -FilePath $obsPath -WorkingDirectory (Split-Path $obsPath)
    } else {
        throw "OBS nicht im Standardpfad gefunden ($obsPath)"
    }
}

function Start-WinEdge {
    param(
        [string]$OpenUrl
    )
    Start-Process "msedge.exe" -ArgumentList $OpenUrl
}