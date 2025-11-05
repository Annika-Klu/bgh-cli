function Get-Songs {
    $ct = [ChurchTools]::new($CT_API_URL)
    $songs = $ct.PaginateRequest("songs", 100)
    $CtSongs = @()
    
    foreach ($song in $songs) {
        $songData = @{
            "name" = $song.name
            "author" = $song.author
            "files" = @()
        }

        foreach ($arragement in $song.arrangements) {
            $pptFiles = $arragement.files | Where-Object { $_.name.Contains(".pptx") }
            if ($pptFiles) {
                $songData.files += $pptFiles
            }
        }
        $CtSongs += $songData
    }
    return $CtSongs
}

function Revoke-SongFilesNotInChurchtools {
    param(
        [array]$CtSongFiles,
        [string]$SongsDir
    )

    $existingFiles = Get-ChildItem -Path $SongsDir -File
    $filesToDelete = $existingFiles | Where-Object {
        $file = $_
        -not ($CtSongFiles | Where-Object { $file.name -eq $_.Name })
    }
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName -Force
    }
    return $filesToDelete.Count
}

function Sync-FromChurchtoolsToLocal {
    param(
        [array]$CtSongFiles,
        [string]$SongsDir
    )
    
    if (-not (Test-Path $SongsDir)) {
        New-Item -ItemType Directory -Path $SongsDir | Out-Null
    }

    $ct = [ChurchTools]::new($CT_API_URL)
    $stats = @{
        "total" = $CtSongFiles.Count
        "new" = 0
        "updated" = 0
    }

    $stats["deleted"] = Revoke-SongFilesNotInChurchtools -CtSongFiles $CtSongFiles -SongsDir $SongsDir
    
    foreach ($file in $CtSongFiles) {
        $savePath = Join-Path $SongsDir $file.name
        if (Test-path $savePath) {
            $lastModifiedDateStr = $file.meta.modifiedDate
            $apiFileLastModified = [DateTime]::ParseExact($lastModifiedDateStr, "yyyy-MM-ddTHH:mm:ssZ", $null)
            $savedFileLastModified = (Get-Item $savePath).LastWriteTime
            if ($apiFileLastModified -gt $savedFileLastModified) {
                Out-Message "Aktualisiere '$($file.name)'"
                $stats["updated"]++
                $ct.CallApi("GET", $file.fileUrl, $null, $savePath)
            }
            continue
        }
        Out-Message "Speichere (neu) '$($file.name)'"
        $stats["new"]++
        $ct.CallApi("GET", $file.fileUrl, $null, $savePath)
    }
    return $stats
}