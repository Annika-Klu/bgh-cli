function Send-ErrorReport {
    param(
        [string]$ErrMsg
    )

    $groupName = "CLI"

    Out-Message "Falls der Fehler hÃ¤ufiger auftritt und du nicht weiterkommst, kannst du ihn in der Gruppe '$groupName' melden." -Type "debug"
    
    $reportError = Get-YesOrNo "Fehler melden?"
    if (-not $reportError) { return }

    $ct = [ChurchTools]::new($CT_API_URL)
    if (-not $ct) {
        Out-Message "Churchtools ist nicht verfÃ¼gbar." -Type "error"
        return
    }
    
    $content = "Fehlermeldung: '$ErrMsg'"
    $additionalInfo = Read-Host "Beschreibung zusÃ¤tzlich zur Fehlermeldung (optional, sonst weiter mit Enter)"
    if ($additionalInfo) { $content += " | ErgÃ¤nzende Beschreibung: $additionalInfo" }
    
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