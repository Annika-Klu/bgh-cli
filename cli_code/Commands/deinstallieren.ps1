try {
    Out-Message "ACHTUNG: Dies kann nicht rückgängig gemacht werden. Um das CLI danach wieder zu nutzen, musst du es erneut installieren." -Type "warning"
    do {
        $confirmUninstall = Read-Host "Deinstallieren? (j, sonst beenden mit Enter)"
    } while ($confirmUninstall -ne "j" -and $confirmUninstall -ne "")
    if ($confirmUninstall -eq "") {
        Out-Message "Deinstallation abgebrochen."
        return
    }
    $TempUpdateFilePath = Invoke-UninstallBootstrap
    $cliInstallPath = $PWD

    Set-Location $env:TEMP
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$TempUpdateFilePath`" -InstallPath `"$cliInstallPath`""

    Out-Message "Deinstallation vorbereitet."
    exit 0
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
}
