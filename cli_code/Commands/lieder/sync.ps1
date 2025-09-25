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

function Sync-FromLocalToChurchtools {
    $songFiles = Get-AllSongFiles
    Out-Message "$($songFiles.Count) Lieddateien gefunden."
    $stats = Sync-SongFiles -SongFiles $songFiles
    $newSongs = $stats.new
    $updatedSongs = $stats.updated
    $deletedSongs = $stats.deleted
    $processedSongs = $newSongs + $updatedSongs + $deletedSongs
    if ($processedSongs -eq 0) {
        $toast.Show("info", "Lieder-Sync von $from nach $to", "Alle Dateien sind aktuell.")
    } else {
        $toast.Show("info", "Lieder-Sync von $from nach $to", "$processedSongs Verarbeitete Datei(en): $newSongs neu, $updatedSongs aktualisert, $deletedSongs entfernt.")
    }
}

try {
    Assert-SyncArg -Key "von" -Value $from
    Assert-SyncArg -Key "nach" -Value $to
    if ($from -eq "churchtools" -and $to -eq "lokal") {
        Sync-FromLocalToChurchtools
    }
} catch {
    Out-Message $_ -Type "error"    
    $toast.Show("error", "Lieder-Sync", $_)
}