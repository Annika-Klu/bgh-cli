$ct = [ChurchTools]::new($CT_API_URL)

function Get-ApiDate {
    param(
        [datetime]$Date
    )
    return $Date.ToString("yyyy-MM-dd")
}

function Save-EventFiles {
    param(
        [datetime]$ForDate = $(Get-Date),
        [string]$SaveDir
    )
    $nextDay = $ForDate.AddDays(1)
    $eventsUrl = "events?include=eventServices&from=$(Get-ApiDate $ForDate)&to=$(Get-ApiDate $nextDay)"
    $events = $ct.CallApi("GET", $eventsUrl, $null, $null)
    if (-not $events) {
        return @()
    }
   
    foreach ($event in $events) {
        $files = $event.eventFiles
        if (-not $files) { continue }
        foreach ($file in $files) {
            $filePath = Join-Path $SaveDir $file.title
            if (Test-Path $filePath) { continue }
            Write-Host "Lade $($file.title) für $($event.name) herunter..."
            $ct.CallApi("GET", $file.frontendUrl, $null, $filePath)
        }
    }

    $childItems = Get-ChildItem -Path $SaveDir -Recurse -File
    $downloadedFiles = $childItems | Where-Object { $_ -is [System.IO.FileInfo] -and $_ -ne "" }
    return @($downloadedFiles)
}