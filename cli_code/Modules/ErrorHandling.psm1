function Write-ErrorReport {
    param(
        [Log]$Log,
        [string]$ErrMsg
    )
    $groupName = "CLI"

    $logMsg = if ($parsedCmd.Subcommands) { 
        "ERROR in '$BASE_CMD $($parsedCmd.Subcommands)': $ErrMsg" }
    else { "ERROR in '$BASE_CMD': $ErrMsg" }

    $Log.Write($logMsg)

    do {
        $choice = Read-Host "Möchtest du den Fehler in der Gruppe '$groupName' melden? (j, sonst weiter mit Enter, dann wird Fehlermeldung nur geloggt)"
    } while ($choice -ne "j" -and $choice -ne "")
    
    if (-not $choice) { return }

    $ct = [ChurchTools]::new($CT_API_URL)
    
    $content = "Fehlermeldung: '$ErrMsg'"
    $additionalInfo = Read-Host "Beschreibung zusätzlich zur Fehlermeldung (optional, sonst weiter mit Enter):"
    if ($additionalInfo) { $content += " | Ergänzende Beschreibung: $additionalInfo" }
    
    $cliGroup = $ct.FindGroup($groupName)
    if (-not $cliGroup) {
        throw "Gruppe '$groupName' konnte nicht gefunden werden oder Churchtools ist nicht erreichbar."
    }
    $comment = @{
        "groupId" = $cliGroup.id
        "title" = "Fehler bei CLI-Befehl '$BASE_CMD'"
        "content" = $content
        "visibility" = "group_intern"
    }
    $res = $ct.CallApi("POST", "posts", $comment, $null)
    $errorReportResult = $res | ConvertTo-Json -Compress
    $Log.Write("ERROR REPORT SENT. RESPONSE: $errorReportResult")
}