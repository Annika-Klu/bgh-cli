try {
    $ct = [ChurchTools]::new($CT_API_URL)
    Out-Message "ACHTUNG: Hierdurch werden die Daten des aktuell angemeldeten Nutzers $($ct.User.firstName) $($ct.User.lastName) gelöscht. " -Type "warning"
    $switchUser = Get-YesOrNo "Mit anderem Benutzer anmelden?"
    if (-not $switchUser) { 
        Out-Message "Weiterhin angemeldet als $($ct.User.firstName) $($ct.User.lastName)"
        return
    }
    $userCacheFile = ".usercache.json"
    if (Test-Path $userCacheFile) {
        Out-Message "Lösche Anmeldedaten von $($ct.User.firstName) $($ct.User.lastName)..."
        Remove-Item $userCacheFile -Force
    }
    Save-ApiToken -ApiUrl $CT_API_URL
    Show-UserAndAddToGroup -ApiUrl $CT_API_URL
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
}