$ct = [ChurchTools]::new($CT_API_URL)

function Save-EventFiles {
    param(
        [datetime]$ForDate = $(Get-Date),
        [string]$SaveDir
    )
    $todayStr = $ForDate.ToString("yyyy-MM-dd")
    $tomorrow = $ForDate.AddDays(1)
    $tomorrowStr = $tomorrow.ToString("yyyy-MM-dd")
    $eventsUrl = "events?include=eventServices&from=$todayStr&to=$tomorrowStr"
    $events = $ct.CallApi("GET", $eventsUrl, $null, $null)
    if (-not $events) {
        throw "Heute sind keine Veranstaltungen in Churchtools geplant. Keine Dateien heruntergeladen."
    }
   
    foreach ($event in $events) {
        $files = $event.eventFiles
        if (-not $files) { continue }
        foreach ($file in $files) {
            $filePath = Join-Path $SaveDir $file.title
            if (Test-Path $filePath) { continue }
            Write-Host "Lade Dateien für $($event.name) herunter..."
            $ct.CallApi("GET", $file.frontendUrl, $null, $filePath)
        }
    }

    $downloadedFiles = Get-ChildItem -Path $SaveDir -Recurse
    return $downloadedFiles
}