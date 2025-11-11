$relevantStatuses = @("Mitglied", "Freund", "Interessent", "Gast")

$backupName = "churchtools_backup_$(Get-FileTimestamp)"
$tempBackupDir = Join-Path $env:TEMP $backupName

try {
    $timer = [Timer]::new()
    $timer.Start()

    $zipFileName = "$backupName.zip"
    $zipFilePath = Join-Path $OUT_DIR $zipFileName

    if (Test-Path $zipFilePath) {
        $overwrite = Get-YesOrNo "$zipFileName existiert bereits. Möchtest du sie überschreiben?"
        if ($overwrite) {
            Remove-Item -Recurse -Force -Path $zipFilePath
        }
        else {
            Out-Message "Backup abgebrochen."
            exit 0
        }
    }

    if (Test-Path $tempBackupDir) {
        Remove-Item -Recurse -Force -Path  $tempBackupDir
    }
    New-Item -ItemType Directory -Path $tempBackupDir | Out-Null
    
    Out-Message "Erstelle Backup..."
    Out-Message "Dies kann einige Minuten dauern, bitte dieses Fenster nicht schließen!"
    
    Out-Line
    Out-Message "Teil 1 von 3 - Personen"
    $timer.SetMarker()
    $persons = Get-PersonsBackupData -StatusNames $relevantStatuses
    $personsBackupFile = Join-Path $tempBackupDir "Personen.csv"
    $persons | Select-Object * | Export-Csv -Path $personsBackupFile -NoTypeInformation -Encoding UTF8
    $timer.LogDurationSinceMarker("Personendaten gespeichert in")

    Out-Line
    Out-Message "Teil 2 von 3 - Lieder"
    $timer.SetMarker()
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
    Sync-FromChurchtoolsToLocal -CtSongFiles $songFiles -SongsDir $tempSongsBackupDir | Out-Null
    $songs | Select-Object Name, Autor, @{Name="Liederbuecher"; Expression={ ($_.Liederbuecher -join ', ') }} | Export-Csv -Path $songsBackupFile -NoTypeInformation -Encoding UTF8

    $timer.LogDurationSinceMarker("Liederdaten gespeichert in")

    Out-Line
    Out-Message "Teil 3 von 3 - Wikis"
    $timer.SetMarker()
    $tempWikisBackupDir = Join-Path $tempBackupDir "Wikis"
    New-Item -ItemType Directory -Path $tempWikisBackupDir | Out-Null

    $wikis = Get-Wikis
    foreach ($wiki in $wikis) {
        Out-Message "Sichere Inhalte von '$($wiki.name)'..."
        $wikiSubDir = Join-Path $tempWikisBackupDir $wiki.name
        New-Item -ItemType Directory -Path $wikiSubDir | Out-Null
        $wikiPages = Get-WikiPages -WikiCategoryId $wiki.id 
        foreach ($page in $wikiPages) {
            $pageDir = Join-Path $wikiSubDir $page.title
            New-Item -ItemType Directory -Path $pageDir | Out-Null
            $pageContentFile = Join-Path $pageDir "$($page.title).txt"
            Save-WikiPage -WikiCategoryId $wiki.id -WikiPageId $page.identifier -SavePath $pageContentFile
            Save-WikiPageFiles -WikiCategoryId $wiki.id -WikiPageId $page.identifier -SaveDir $pageDir
        }
    }
    $timer.LogDurationSinceMarker("Wikidaten gespeichert in")
    Out-Line

    $backupStats = Get-DirStats -DirPath $tempBackupDir
    Compress-FilesToZip -SourceFolder $tempBackupDir -ZipFilePath $zipFilePath
    Remove-Item -Recurse -Force -Path $tempBackupDir

    $timer.Stop()
    Out-Message "Backup erstellt: $zipFilePath"
    $timer.LogDuration("Gesamtdauer:")
    Out-Message "Dateien: $($backupStats.FileCount)"
    Out-Message "Größe: $($backupStats.TotalSizeMB)MB"
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
    if (Test-Path $tempBackupDir) {
        Remove-Item -Recurse -Force -Path $tempBackupDir
    }
}