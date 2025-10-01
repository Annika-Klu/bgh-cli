$ct = [ChurchTools]::new($CT_API_URL)

try {
    Out-Line
    Out-Message "CLI-Version $VERSION"
    Out-Message "Angemeldet als $($ct.User.firstName) $($ct.User.lastName)"
    Out-Message "Email: $($ct.User.email)"
    Out-Message "Konfiguriertes Download-Verzeichnis: $OUT_DIR"
    Out-Line
} catch {
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
}