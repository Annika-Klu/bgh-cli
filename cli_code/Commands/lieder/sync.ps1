$toast = [Toast]::new()

$from = $parsedCmd.Arguments.von
$to = $parsedCmd.Arguments.nach

function Assert-SyncArg {
    param(
        [string]$Key,
        [string]$Value
    )
    
    $validArgs = ("churchtools", "lokal")
    $errMsg = "Falsches Argument für '$Key'. Akzeptierte Werte: $($validArgs -join ', ')"
    if (-not $Value -or $Value -eq "") {
        throw $errMsg
    }

    if ($Value -notin $validArgs) {
        throw $errMsg
    }
}

try {
    Assert-SyncArg -Key "von" -Value $from
    Assert-SyncArg -Key "nach" -Value $to

    $ctSongFiles = Get-ChurchtoolsSongFiles
    Out-Message "$($ctSongFiles.Count) Lieddateien gefunden."
    $songsDir = Join-Path $OUT_DIR "Lieder"

    if ($from -eq "churchtools" -and $to -eq "lokal") {
       $stats = Sync-FromChurchtoolsToLocal -CtSongFiles $ctSongFiles -SongsDir $songsDir
    } else {
        Out-Message "Sync von $from nach $to folgt noch. Hier ist Vorsicht geboten, da Churchtools die zentrale Datenquelle ist."
        exit 0
    }

    $newSongs = $stats.new
    $updatedSongs = $stats.updated
    $deletedSongs = $stats.deleted
    $processedSongs = $newSongs + $updatedSongs + $deletedSongs
    if ($processedSongs -eq 0) {
        $toast.Show("info", "Lieder-Sync von $from nach $to", "Alle Dateien sind aktuell.")
    } else {
        $toast.Show("info", "Lieder-Sync von $from nach $to", "$processedSongs Verarbeitete Datei(en): $newSongs neu, $updatedSongs aktualisert, $deletedSongs entfernt.")
    }
} catch {
    Out-Message $_ -Type "error"    
    $toast.Show("error", "Lieder-Sync", $_)
}