function Send-ErrorReport {
    param(
        [string]$ErrMsg
    )

    $groupName = "CLI"

    Out-Message "Falls der Fehler häufiger auftritt und du nicht weiterkommst, kannst du ihn in der Gruppe '$groupName' melden." -Type "debug"
    
    if ($CLI_TESTMODE) {
        Out-Message "Skipping error msg post request due to test mode" -Type "debug"
        return
    }
    
    $reportError = Get-YesOrNo "Fehler melden?"
    if (-not $reportError) { return }

    $ct = [ChurchTools]::new($CT_API_URL)
    if (-not $ct) {
        Out-Message "Churchtools ist nicht verfügbar." -Type "error"
        return
    }

    
    $content = "Fehlermeldung: '$ErrMsg'"
    $additionalInfo = Read-Host "Beschreibung zusätzlich zur Fehlermeldung (optional, sonst weiter mit Enter)"
    if ($additionalInfo) { $content += " | Ergänzende Beschreibung: $additionalInfo" }
    
    $cliGroup = $ct.FindGroup($groupName)
    if (-not $cliGroup) {
        throw "Gruppe '$groupName' konnte nicht gefunden werden oder Churchtools ist nicht erreichbar."
    }

    $cmdInfo = if ($parsedCmd.Subcommands) { 
        "$BASE_CMD $($parsedCmd.Subcommands)"
    } else { $BASE_CMD }

    $comment = @{
        "groupId" = $cliGroup.id
        "title" = "Fehler bei CLI-Befehl '$cmdInfo'"
        "content" = $content
        "visibility" = "group_intern"
    }
    $ct.CallApi("POST", "posts", $comment, $null) | Out-Null
    Out-Message "Fehlerbericht gesendet."
}

function Write-ErrorMessage {
    param(
        [Log]$Log,
        [string]$ErrMsg
    )

    $logMsg = if ($parsedCmd.Subcommands) { 
        "ERROR '$BASE_CMD $($parsedCmd.Subcommands)': $ErrMsg" }
    else { "ERROR '$BASE_CMD': $ErrMsg" }

    $Log.Write($logMsg)
}