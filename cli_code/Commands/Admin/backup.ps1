$relevantStatuses = @("Mitglied", "Freund", "Interessent", "Gast")

$backupName = "churchtools_backup_$(Get-FileTimestamp)"
$tempBackupDir = Join-Path $env:TEMP $backupName

try {
    New-Item -ItemType Directory -Path $tempBackupDir | Out-Null
    Out-Message $tempBackupDir
    Out-Message "Erstelle Backup..."
    $persons = Get-PersonsBackupData -StatusNames $relevantStatuses
    $personsBackupFile = Join-Path $tempBackupDir "personen.csv"
    $persons | Export-Csv -Path $personsBackupFile -NoTypeInformation

    $zipFileName = "$backupName.zip"
    $zipFilePath = Join-Path $OUT_DIR $zipFileName
    Out-Message "Backup erstellt: $zipFilePath"
    Compress-FilesToZip -SourceFolder $tempBackupDir -ZipFilePath $zipFilePath

    Remove-Item -Recurse -Force -Path $tempBackupDir
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
}