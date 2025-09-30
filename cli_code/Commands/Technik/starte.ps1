$toast = [Toast]::new()

$device = $null
$validDevices = @("pc", "notebook")

function Assert-DeviceArg {
    if (-not $parsedCmd.Arguments -or (-not $parsedCmd.Arguments.ContainsKey("auf"))) {
        throw "Pflichtargument 'auf' (pc oder notebook) fehlt"
    }
    $device = $parsedCmd.Arguments.auf
    if ($device -notin $validDevices) {
        throw "Ungültiges Argument für 'auf': $device"
    }
    return $device
}

function Start-TechnikNotebook {
    $downloadFilesDir = Join-Path $OUT_DIR "Eventdateien"
    if (Test-Path $downloadFilesDir) {
        Remove-Item "$downloadFilesDir\*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $downloadFilesDir | Out-Null
    }

    $pptToday = $null
    try {
        $downloadedFiles = Save-EventFiles -SaveDir $downloadFilesDir
        $downloadedTotal = $downloadedFiles.Count

        if ($downloadedTotal -eq 0) {
            $toast.Show("info", "Downloads", "Heute sind keine Veranstaltungen geplant oder es gibt keine Dateien dafür.")
        } else {
            $toast.Show("info", "Downloads", "$downloadedTotal Dateien für heutige Veranstaltung(en) heruntergeladen.")
            $pptFiles = $downloadedFiles | Where-Object { $_.Name -like "*.pptx" }
            if ($pptFiles.Count -gt 1) {
                $toast.Show("info", "Mehrere PowerPoint-Dateien geladen", "Bitte im Download-Ordner schauen, welche geöffnet werden soll.")
            } else {
                $pptToday = $pptFiles[0]
            }
        }
    } catch {
        $toast.Show("error", "Downloads", $_)
    }

    if ($pptToday) {
        try {
            Start-Process $pptToday.FullName
        } catch {
            $toast.Show("error", "Öffnen der PowerPoint-Datei", $_)
        }
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
        Start-MSEdge -OpenUrl $YT_STREAM_URL
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
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    if ($parsedCmd.Flags.job) {
        $ToastTitle = "Technikstart"
        if ($device) { $ToastTitle += " (auf $device)"}
        $toast.Show("error", $ToastTitle, $_)
        exit 0
    } 
    Out-Message $_ -Type "error"
    Send-ErrorReport -ErrMsg $_.Exception.Message
}