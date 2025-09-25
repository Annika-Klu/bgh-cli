$ct = [ChurchTools]::new($CT_API_URL)
$toast = [Toast]::new()

$device = $null
$validDevices = @("pc", "notebook")

function Assert-DeviceArg {
    if (-not $parsedCmd.Arguments -or (-not $parsedCmd.Arguments.ContainsKey("device"))) {
        throw "Pflichtargument 'device' (pc oder notebook) fehlt"
    }
    $device = $parsedCmd.Arguments.device
    if ($device -notin $validDevices) {
        throw "Ungültiges Argument für 'device': $device"
    }
    return $device
}

function Start-TechnikNotebook {
    $downloadFilesDir = Join-Path $env:USERPROFILE "Desktop/Churchtools_Downloads"
    if (Test-Path $downloadFilesDir) {
        Remove-Item "$downloadFilesDir\*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $downloadFilesDir
    }

    try {
        $downloadedFiles = Save-EventFiles -SaveDir $downloadFilesDir
        $downloadedTotal = $downloadedFiles.Count
        if ($downloadedTotal -eq 0) {
            $toast.Show("info", "Downloads", "Heute sind keine Veranstaltungen geplant oder es gibt keine Dateien dafür.")
        } else {
            $toast.Show("info", "Downloads", "$downloadedTotal Dateien für heutige Veranstaltung(en) heruntergeladen.")
        }
    } catch {
        $toast.Show("error", "Downloads", $_)
    }

    try {
        Start-OBS
    } catch {
        $toast.Show("error", "OBS", $_)
    }
    try {
        Connect-BenQNetwork
    } catch {
        $toast.Show("error", "Beamer (BenQ)", $_)
    }
}

function Start-TechnikPC {
    try {
        Start-OBS
    } catch {
        $toast.Show("error", "OBS", $_)
    }
    try {
        Start-MsEdge -OpenUrl $YT_STREAM_URL
    } catch {
        $toast.Show("error", "Microsoft Edge", $_)
    }
}

try {
    $device = Assert-DeviceArg
    switch($device) {
        "notebook" {
            Start-TechnikNotebook
        }
        "pc" {
            Start-TechnikPC
        }
    }
} catch {
    Write-Host $_
    $ToastTitle = "Technikstart"
    if ($device) { $ToastTitle += " (auf $device)"}
    $toast.Show("error", $ToastTitle, $_)
}