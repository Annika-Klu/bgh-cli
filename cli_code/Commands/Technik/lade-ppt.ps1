$ct = [ChurchTools]::new($CT_API_URL)
$toast = [Toast]::new()

function Get-PowerPoint {
    param(
        [DateTime]$today
    )
    $eventsUrl = "events?direction=forward&limit=1&include=eventServices&from=$($today.ToString("yyyy-MM-dd"))&page=1"
    $data = $ct.CallApi("GET", $eventsUrl, $null, $null)
    $eventStart = Get-Date -Date $data.startDate

    if ($eventStart.Date -gt $today.Date) {
        throw "Zu heute ist keine Veranstaltung in Churchtools geplant. Keine Datei heruntergeladen."
    }
    if (-not $data.eventFiles) {
        throw "$($data.name): Keine Dateien gefunden"
    }
    $pptx = $data.eventFiles | Where-Object { $_.title -like "*.pptx*" }
    if (-not $pptx) {
        throw "$($data.name): Keine PowerPoint-Datei gefunden"
    }
    return @{
        eventName = $data.name
        pptName = $pptx.title
        pptUrl = $pptx.frontendUrl
    }
}


try {
    $today = Get-Date

    $fileData = Get-PowerPoint -today $today
    if (-not $fileData) {
        return
    }
    $ct.CallApi("GET", $fileData.pptUrl, $null, "$OUT_DIR\$($fileData.pptName)")
    $toast.Show("info", "$($fileData.eventName) - Datei", "'$($fileData.pptName)' erfolgreich heruntergeladen")
} catch {
   $toast.Show("error", "PowerPoint-Download", $_)
}
