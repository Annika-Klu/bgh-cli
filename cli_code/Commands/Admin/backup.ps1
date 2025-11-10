$relevantStatuses = @("Mitglied", "Freund", "Interessent", "Gast")

$backupName = "churchtools_backup_$(Get-FileTimestamp)"
$tempBackupDir = Join-Path $env:TEMP $backupName

try {
    New-Item -ItemType Directory -Path $tempBackupDir | Out-Null
    Out-Message $tempBackupDir
    Out-Message "Erstelle Backup..."
    
    $persons = Get-PersonsBackupData -StatusNames $relevantStatuses
    $personsBackupFile = Join-Path $tempBackupDir "Personen.csv"
    $persons | Select-Object * | Export-Csv -Path $personsBackupFile -NoTypeInformation -Encoding UTF8

    $tempSongsBackupDir = Join-Path $tempBackupDir "Lieder"
    New-Item -ItemType Directory -Path $tempSongsBackupDir | Out-Null
    $songsBackupFile = Join-Path $tempSongsBackupDir "Lieder.csv"
    $songs = Get-Songs
    
 
    $songFiles = @()
    foreach ($song in $songs) {
        if ($song.files.Count -gt 0) {
            $songFiles += $song.files
        }
    }
    Sync-FromChurchtoolsToLocal -CtSongFiles $songFiles -SongsDir $tempSongsBackupDir
    $songs | Select-Object Name, Autor, @{Name="Liederbuecher"; Expression={ ($_.Liederbuecher -join ', ') }} | Export-Csv -Path $songsBackupFile -NoTypeInformation -Encoding UTF8

    $zipFileName = "$backupName.zip"
    $zipFilePath = Join-Path $OUT_DIR $zipFileName
    Out-Message "Backup erstellt: $zipFilePath"
    Compress-FilesToZip -SourceFolder $tempBackupDir -ZipFilePath $zipFilePath

    Remove-Item -Recurse -Force -Path $tempBackupDir
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
    if (Test-Path $tempBackupDir) {
        Remove-Item -Recurse -Force -Path $tempBackupDir
    }
}