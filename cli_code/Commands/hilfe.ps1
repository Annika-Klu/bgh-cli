try {
    Show-Help
} catch {
    Write-ErrorReport -Log $log -ErrMsg $_.Exception.Message
}